defmodule LiveSecret.Sync do
  alias Ecto.Adapters.FoundationDB

  alias Phoenix.Component
  alias Phoenix.LiveView

  @doc """
  Initializes a Sync of a single record.

  This is to be paired with `handle_ready/3` to provide automatic updating of `assigns` in `state`.

  ## Arguments

  - `state`: A map with key `:assigns` and `:private`. `private` must be a map with key `:tenant`
  - `name`: Unique name for the sync (identifier for attach_hook)
  - `repo`: An Ecto repository
  - `shema`: The schema of the record to sync
  - `label`: The label to assign the synced record to
  - `id`: The id of the record to sync
  - `opts`: Options

  ## Options

  - `assign`: A function that takes the current socket and new assigns and returns a tuple of new assigns and state.
    By default, we simply update the assigns map with the new labels. The default is not sufficient for LiveView's assign
  - `attach_hook`: A function that takes `state, name, repo, opts` and modifies state as needed to attach a hook. Defaults to a function that uses LiveView.attach_hook.
  - `post_hook`: A function that takes `state` and modifies it as desired after the hook is executed. Defaults to a noop

  ## Return

  The `state` is updated according to the behavior of `sync_many!/3`.

  """
  def sync_one!(state, name, repo, schema, label, id, opts \\ []) do
    sync_many!(state, name, repo, [{schema, label, id}], opts)
  end

  @doc """
  Initializes a Sync of several individual records.

  This is to be paired with `handle_ready/3` to provide automatic updating of `assigns` in `state`.

  ## Arguments

  - `state`: A map with key `:assigns` and `:private`. `private` must be a map with key `:tenant`
  - `name`: Unique name for the sync (identifier for attach_hook)
  - `repo`: An Ecto repository
  - `id_assigns`: A list of tuples with schema, label, and id
  - `opts`: Options

  ## Options

  - `assign`: A function that takes the current socket and new assigns and returns a tuple of new assigns and state.
    By default, we simply update the assigns map with the new labels. The default is not sufficient for LiveView's assign
  - `attach_hook`: A function that takes `state, name, repo, opts` and modifies state as needed to attach a hook. Defaults to a function that uses LiveView.attach_hook.
  - `post_hook`: A function that takes `state` and modifies it as desired after the hook is executed. Defaults to a noop

  ## Return

  Returns an updated `state`, with `:assigns` and `:private` updated with the following values:

  ### `assigns`

  - Provided labels from `id_assigns` are used to register the results from `repo.get!/3`. For
    any records not found, `nil` is assigned, and no watch is created.

  ### `private`

  - We add or append to the `:futures` list.

  """
  def sync_many!(state, name, repo, id_assigns, opts \\ []) do
    %{private: private} = state
    %{tenant: tenant} = private

    futures = Map.get(private, :futures, [])

    {new_assigns, new_futures} =
      repo.transactional(
        tenant,
        fn ->
          get_futures =
            for {schema, _label, id} <- id_assigns, do: repo.async_get(schema, id)

          labels = for {_schema, label, _id} <- id_assigns, do: label

          values =
            for value <- repo.await(get_futures) do
              if is_nil(value), do: value, else: FoundationDB.usetenant(value, tenant)
            end

          labeled_values = Enum.zip(labels, values)

          watch_futures =
            for {label, value} <- labeled_values,
                not is_nil(value),
                do: repo.watch(value, label: label)

          {labeled_values, watch_futures}
        end
      )

    private = Map.put(private, :futures, futures ++ new_futures)
    state = %{state | private: private}

    state
    |> apply_assign(new_assigns, opts)
    |> apply_attach_hook(name, repo, opts)
  end

  @doc """
  This hook can be attached to a compatible Elixir process to automatically
  process handle_info `:ready` messages from EctoFDB.

  This hook is designed to be used with LiveView's `attach_hook`.

  ## Agruments

  - `repo`: An Ecto repository.
  - `info`: A message received on the process mailbox. We will inspect messages of the form
     `{ref, :ready} when is_reference(ref)`, and ignore all others (returning `{:cont, state}`).
  - `state`: A map with key `:assigns` and `:private`. `private` must be a map with keys `:tenant` and `:futures`.
  - `opts`: Options

  ## Options

  - `assign`: A function that takes the current socket and new assigns and returns a tuple of new assigns and state.
    By default, we simply update the assigns map with the new labels. The default is not sufficient for LiveView's assign

  ## Result behavior

  Either `{:cont, state}` or `{:halt, state}` is returned.

  - `:cont`: Returned when the message was not processed by the Repo.
  - `:halt`: Returned when the ready message is relevant to the provided
    `futures`. The `assigns` and `private` are updated accordingly based on the label
    provided to the matching future. The watches are re-initialized so that
    the expected syncing behavior will continue.

  """
  def handle_ready(repo, info, state, opts \\ [])

  def handle_ready(repo, {ref, :ready}, state, opts) when is_reference(ref) do
    %{private: private} = state
    %{tenant: tenant} = private
    futures = Map.get(private, :futures, [])

    case repo.assign_ready(futures, [ref], watch?: true, prefix: tenant) do
      {[], ^futures} ->
        {:cont, state}

      {new_assigns, futures} ->
        private = Map.put(private, :futures, futures)
        state = %{state | private: private}

        {:halt,
         state
         |> apply_assign(new_assigns, opts)
         |> apply_post_hook(opts)}
    end
  end

  def handle_ready(_repo, _info, state, _opts) do
    {:cont, state}
  end

  defp apply_assign(state, new_assigns, opts) do
    apply_callback(:assign, [state, new_assigns], opts, fn state, new_assigns ->
      Component.assign(state, new_assigns)
    end)
  end

  defp apply_attach_hook(state, name, repo, opts) do
    apply_callback(:attach_hook, [state, name, repo, opts], opts, fn state, name, repo, opts ->
      state
      |> LiveView.detach_hook(name, :handle_info)
      |> LiveView.attach_hook(name, :handle_info, &handle_ready(repo, &1, &2, opts))
    end)
  end

  defp apply_post_hook(state, opts) do
    apply_callback(:post_hook, [state], opts, fn state ->
      state
    end)
  end

  defp apply_callback(key, args, opts, default) do
    cb = opts[key]

    if is_nil(cb) do
      Kernel.apply(default, args)
    else
      Kernel.apply(cb, args)
    end
  end

  def assign(state, new_assigns) do
    %{assigns: assigns} = state
    assigns = Map.merge(assigns, Enum.into(new_assigns, %{}))
    %{state | assigns: assigns}
  end
end
