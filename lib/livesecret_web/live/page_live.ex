defmodule LiveSecretWeb.PageLive do
  use LiveSecretWeb, :live_view

  alias Ecto.Adapters.FoundationDB

  alias LiveSecret.Presecret
  alias LiveSecret.Repo
  alias LiveSecret.Secret

  alias LiveSecretWeb.ActiveUser
  alias LiveSecretWeb.PageComponents
  alias LiveSecretWeb.SecretFormComponent

  require Logger

  @impl true
  def mount(%{"id" => id, "key" => key}, %{}, socket = %{assigns: %{live_action: :admin}}) do
    case assign_secret_or_redirect(socket, id) do
      {:ok, socket} ->
        %{assigns: %{secret: secret}} = socket

        assert_creator_key!(secret, key)

        {:ok,
         socket
         |> assign(:page_title, "Managing Secret")
         |> assign(:changeset, Secret.managing_changeset(secret))
         |> assign(:special_action, nil)
         |> assign(:self_burned?, false)
         |> detect_presence()}

      socket ->
        {:ok, socket}
    end
  end

  def mount(%{"id" => id}, %{}, socket = %{assigns: %{live_action: :receiver}}) do
    case assign_secret_or_redirect(socket, id) do
      {:ok, socket} ->
        {:ok,
         socket
         |> assign(:page_title, "Receiving Secret")
         |> assign(:special_action, nil)
         |> assign(:self_burned?, false)
         |> detect_presence()}

      {_error, socket} ->
        {:ok, socket}
    end
  end

  def mount(_params, %{}, socket = %{assigns: %{live_action: :create}}) do
    {:ok,
     socket
     |> assign(:page_title, "LiveSecret")
     |> assign(:secret, %Secret{})
     |> assign(:futures, [])
     |> assign(:special_action, nil)
     |> assign(:self_burned?, false)
     |> assign(:changeset, Presecret.changeset(Presecret.new(), %{}))}
  end

  @impl true

  # Validates form data during secret creation
  def handle_event(
        "validate",
        %{"presecret" => attrs},
        socket = %{assigns: %{changeset: _changeset}}
      ) do
    %{assigns: %{tenant: tenant}} = socket
    changeset = LiveSecret.validate_presecret(tenant, attrs)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("do_update", %{"secret" => attrs}, socket) do
    %{assigns: assigns = %{secret: secret}} = socket

    case assigns do
      %{do_update_tref: tref} ->
        :timer.cancel(tref)

      _ ->
        :ok
    end

    {:ok, tref} =
      :timer.apply_after(1000, fn ->
        changeset = Secret.managing_changeset(secret, attrs)
        LiveSecret.update!(changeset)
      end)

    {:noreply, socket |> assign(:do_update_tref, tref)}
  end

  # Submit form data for secret creation
  def handle_event("create", %{"presecret" => attrs}, socket) do
    %{assigns: %{tenant: tenant}} = socket
    secret = %Secret{id: id, creator_key: creator_key} = LiveSecret.insert!(tenant, attrs)

    case assign_secret_or_redirect(socket, id) do
      {:ok, socket} ->
        {:noreply,
         socket
         |> assign(:page_title, "Managing Secret")
         |> assign(:changeset, Secret.managing_changeset(secret))
         |> push_patch(to: ~p"/admin/#{id}?key=#{creator_key}")}

      {_error, socket} ->
        {:noreply, socket}
    end
  end

  # Unlock a specific user for content decryption
  def handle_event(
        "unlock",
        %{"id" => user_id},
        socket = %{assigns: %{live_action: :admin}}
      ) do
    %{assigns: %{secret: secret}} = socket
    # presence meta must be updated from the "owner" process so we have to broadcast first
    # so that we can select the right user
    LiveSecret.notify_unlocked!(secret.id, user_id)
    {:noreply, socket}
  end

  def handle_event("go_async", _params, socket = %{assigns: %{live_action: :admin}}) do
    %{assigns: %{tenant: tenant, secret: secret, users: users}} = socket
    LiveSecret.go_async!(tenant, secret.id)

    # unlock all users currently online
    for {user_id, %ActiveUser{live_action: :receiver, state: :locked}} <- users do
      LiveSecret.notify_unlocked!(secret.id, user_id)
    end

    {:noreply, socket}
  end

  def handle_event("go_live", _params, socket = %{assigns: %{live_action: :admin}}) do
    %{assigns: %{tenant: tenant, secret: secret}} = socket
    LiveSecret.go_live!(tenant, secret.id)

    # Cannot lock a user if they're already unlocked, so no broadcast here

    {:noreply, socket}
  end

  # Burn the secret so that no one else can access it
  def handle_event("burn", params, socket) do
    %{
      assigns: %{
        secret: secret,
        current_user: current_user,
        live_action: live_action,
        users: users
      }
    } = socket

    if assert_burnkey_match(params, secret) and
         live_action === :receiver do
      LiveSecretWeb.Presence.on_revealed(secret.id, users[current_user.id])
    end

    if assert_burnable(live_action, params, secret) do
      %Secret{} = LiveSecret.burn!(secret)
    end

    {:noreply, socket |> assign(self_burned?: true)}
  end

  def handle_event("decrypt_failure", %{"count" => count}, socket) do
    %{
      assigns: %{
        secret: secret,
        current_user: current_user,
        users: users
      }
    } = socket

    LiveSecretWeb.Presence.on_decrypt_failure(secret.id, users[current_user.id], count)
    {:noreply, socket}
  end

  @impl true
  # Handle the push_patch after secret creation. We use a patch so that the DOM doesn't get
  # reset. This allows the client browser to hold onto the passphrase so the instructions
  # can be generated.
  def handle_params(
        %{"id" => id, "key" => key},
        _url,
        socket = %{assigns: %{live_action: :admin}}
      ) do
    case assign_secret_or_redirect(socket, id) do
      {:ok, socket} ->
        %{assigns: %{secret: secret}} = socket

        assert_creator_key!(secret, key)

        {:noreply,
         socket
         |> detect_presence()}

      {_error, socket} ->
        {:noreply, socket}
    end
  end

  def handle_params(params, _, socket) do
    if socket.assigns.live_action == :create and map_size(params) == 0 and
         !is_nil(socket.assigns.secret.id) do
      # This clause is a consequence of us using 'push_patch' on secret creation.
      # After creation, if the user uses the browser 'back' button, LiveView will give us
      # a handle_params (this clause) without a mount. To ensure we fully reset the page,
      # we force a navigation to the root path.
      {:noreply, push_navigate(socket, to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  # Handles presence -- users coming online and offline from the page
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  # Broadcast to all listeners when a user is unlocked. However, only the specific user
  # should do anything with it.
  def handle_info({:unlocked, user_id}, socket) do
    %{assigns: %{current_user: current_user, secret: secret, users: users}} =
      socket

    case current_user.id do
      ^user_id ->
        if LiveSecretWeb.Presence.on_unlocked(secret.id, users[user_id]) do
          {:noreply,
           socket
           |> assign(:special_action, :decrypting)}
        else
          {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({ref, :ready}, socket) when is_reference(ref) do
    %{assigns: %{tenant: tenant, futures: futures}} = socket

    {new_assigns, new_futures} = Repo.assign_ready(futures, [ref], prefix: tenant, watch?: true)

    case Keyword.fetch(new_assigns, :secret) do
      {:ok, nil} ->
        {:noreply,
         socket
         |> assign(:secret, %Secret{})
         |> put_flash(:info, "The secret has expired. You've been redirected to the home page.")
         |> push_navigate(to: ~p"/")}

      {:ok, secret} ->
        # workaround for [ecto_foundationdb/#37](https://github.com/ecto-foundationdb/ecto_foundationdb/issues/37)
        secret = FoundationDB.usetenant(secret, tenant)
        new_assigns = Keyword.put(new_assigns, :secret, secret)

        {:noreply,
         socket
         |> assign(new_assigns)
         |> assign(:futures, new_futures)}

      _ ->
        {:noreply,
         socket
         |> assign(new_assigns)
         |> assign(:futures, new_futures)}
    end
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user_id, %{metas: [active_user = %ActiveUser{} | _]}},
                                  socket ->
      %{assigns: %{users: users}} = socket
      users = Map.put(users, user_id, active_user)
      assign(socket, :users, users)
    end)
  end

  defp handle_leaves(socket, leaves) do
    left_at = NaiveDateTime.utc_now()

    Enum.reduce(leaves, socket, fn {user_id, _}, socket ->
      %{assigns: %{users: users}} = socket

      case users[user_id] do
        nil ->
          socket

        active_user ->
          active_user = %ActiveUser{active_user | left_at: left_at}

          assign(socket, :users, Map.put(users, user_id, active_user))
      end
    end)
  end

  defp assert_creator_key!(secret, key) do
    ^key = secret.creator_key
  end

  def assert_burnkey_match(params, secret) do
    burn_key = params["secret"]["burn_key"]

    case secret.burn_key do
      ^burn_key ->
        true

      _ ->
        false
    end
  end

  def assert_burnable(live_action, params, secret) do
    case live_action do
      :admin ->
        true

      _ ->
        assert_burnkey_match(params, secret)
    end
  end

  def detect_presence(socket = %{assigns: %{presence: _}}) do
    socket
  end

  def detect_presence(socket = %{assigns: %{current_user: user}})
      when not is_nil(user) do
    %{assigns: %{secret: secret, live_action: live_action}} = socket

    active_user =
      ActiveUser.new(
        user[:id],
        user[:name],
        live_action,
        NaiveDateTime.utc_now(),
        if(secret.live?, do: :locked, else: :unlocked)
      )

    special_action =
      case {live_action, active_user.state} do
        {_, :locked} -> nil
        {:admin, _} -> nil
        {:receiver, :unlocked} -> :decrypting
      end

    presence_pid = LiveSecretWeb.Presence.track(secret.id, active_user)

    socket
    |> assign(:users, %{user.id => active_user})
    |> assign(:presence, presence_pid)
    |> assign(:special_action, special_action)
    |> handle_joins(LiveSecretWeb.Presence.list(Secret.topic(secret.id)))
  end

  def detect_presence(socket = %{assigns: %{secret: secret}}) do
    topic = Secret.topic(secret.id)

    socket
    |> assign(:users, %{})
    |> handle_joins(LiveSecretWeb.Presence.list(topic))
  end

  def assign_secret_or_redirect(socket, id) do
    %{assigns: assigns = %{tenant: tenant}} = socket

    case LiveSecret.watch_secret(tenant, :secret, id) do
      {:ok, {secret, watch}} ->
        futures = Map.get(assigns, :futures, [])
        new_assigns = [secret: secret, futures: [watch | futures]]

        {:ok, assign(socket, new_assigns)}

      error ->
        Logger.info("#{id} not found: #{inspect(error)}")

        {error,
         socket
         |> put_flash(
           :error,
           "That secret doesn't exist. You've been redirected to the home page."
         )
         |> assign(:secret, %Secret{})
         |> push_navigate(to: ~p"/")}
    end
  end
end
