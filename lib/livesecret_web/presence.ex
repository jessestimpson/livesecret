defmodule LiveSecretWeb.Presence do
  use Phoenix.Presence,
    otp_app: :livesecret,
    pubsub_server: LiveSecret.PubSub

  alias LiveSecret.Secret
  alias LiveSecret.Do
  alias LiveSecretWeb.ActiveUser
  alias Phoenix.LiveView

  require Logger

  def tenant_from_socket(socket) do
    with %URI{host: host} <- LiveView.get_connect_info(socket, :uri) do
      # Note: currently no authn/authz. Any user can connect to any supported tenant.
      presence_config = Application.fetch_env!(:livesecret, LiveSecretWeb.Presence)
      allowed_tenants = presence_config[:tenants]

      if host in allowed_tenants do
        Do.open_tenant(host)
      else
        raise """
        LiveSecret is configured to allow connections from #{inspect(allowed_tenants)}.

        Use the TENANTS env var to manage allowed tenants.
        """
      end
    else
      _ ->
        nil
    end
  end

  @doc """
  Builds a map of user info from the current socket
  """
  def user_from_socket(socket) do
    case socket.private[:connect_info] do
      %Plug.Conn{} ->
        # User id cannot be constructed until the websocket connects, so the first render
        # does not have a current_user so the presence list is not shown. This check is
        # inspecting LiveView private data, but it appears to be the only way.
        nil

      _ ->
        _user_from_socket(socket)
    end
  end

  defp _user_from_socket(socket) do
    with %{address: address, port: port} <- LiveView.get_connect_info(socket, :peer_data) do
      x_headers = LiveView.get_connect_info(socket, :x_headers)

      presence_config = Application.fetch_env!(:livesecret, LiveSecretWeb.Presence)

      Logger.debug("presence_config is #{inspect(presence_config)}")

      direct_address = :erlang.iolist_to_binary(:inet.ntoa(address))
      direct_id = "#{direct_address}:#{port}"

      case presence_config[:behind_proxy] do
        true ->
          # You can only configure headers that start with "x-" because that's all LiveView is
          # presenting to us in the connect_info. Is there a way to support a header that
          # does not start with "x-", for example "Fly-Client-Ip"?
          address =
            RemoteIp.from(x_headers,
              headers: [presence_config[:remote_ip_header]],
              proxies: presence_config[:remote_ip_proxies],
              clients: presence_config[:remote_ip_clients]
            )

          # A lack of address is not acceptable. If we crash here, something is wrong with
          # the reverse proxy. Ensure that it is presenting the expected headers to work
          # with the remote_ip application.
          #
          # Note: Make sure you are not pointing your browser at the Phoenix port when setting
          # :behind_proxy to true
          not is_nil(address) ||
            raise """
            LiveSecret was not able to find the client address from the configured header \
            "#{presence_config[:remote_ip_header]}".
              1. Do not point a browser directly at the Phoenix port when running BEHIND_PROXY=true
              2. Ensure you have configured the trusted header containing the client IP address (REMOTE_IP_HEADER)
            """

          address = :erlang.iolist_to_binary(:inet.ntoa(address))
          %{id: "#{address}__via__#{direct_id}", name: "#{address} (via #{direct_id})"}

        false ->
          %{id: direct_id, name: direct_id}
      end
    else
      _ ->
        nil
    end
  end

  @doc """
  Track a user in presence for this secret
  """
  def track(id, user) do
    presence =
      case LiveSecretWeb.Presence.track(self(), Secret.topic(id), user.id, user) do
        {:ok, pid} ->
          pid

        {:error, {:already_tracked, pid, _topic, _userid}} ->
          pid
      end

    LiveSecret.subscribe!(id)

    presence
  end

  @doc """
  Updates presence for an active user to the unlocked state

  Must be called from the process that manages the user that is being unlocked.

  Returns true if successful
  """
  def on_unlocked(
        id,
        for_user = %ActiveUser{live_action: :receiver, state: :locked, left_at: nil}
      ) do
    {:ok, _} =
      LiveSecretWeb.Presence.update(self(), Secret.topic(id), for_user.id, %ActiveUser{
        for_user
        | state: :unlocked
      })

    true
  end

  def on_unlocked(_id, _for_user) do
    false
  end

  @doc """
  Updates presence for active user to 'revealed'

  Must be called from the process that manages the user that is being unlocked.

  Returns true if successful
  """
  def on_revealed(id, for_user) do
    LiveSecretWeb.Presence.update(self(), Secret.topic(id), for_user.id, %ActiveUser{
      for_user
      | state: :revealed
    })

    true
  end

  @doc """
  Notifies listeners that a user has failed to decrypt a secret

  Must be called from the process that manages the user that is unlocked for decryption.

  Returns true if successful
  """
  def on_decrypt_failure(id, for_user, count) do
    LiveSecretWeb.Presence.update(self(), Secret.topic(id), for_user.id, %ActiveUser{
      for_user
      | decrypt_failure_count: count
    })

    true
  end
end
