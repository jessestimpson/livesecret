defmodule LiveSecretWeb.InitAssigns do
  alias Phoenix.Component
  alias Phoenix.LiveView
  alias LiveSecretWeb.Presence

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> put_private_new_not_nil(:tenant, &Presence.tenant_from_socket/1)
     |> assign_new_not_nil(:current_user, &Presence.user_from_socket/1)}
  end

  defp put_private_new_not_nil(socket, key, fun) do
    %{private: private} = socket

    case Map.get(private, key, nil) do
      nil ->
        LiveView.put_private(socket, key, fun.(socket))

      _val ->
        socket
    end
  end

  defp assign_new_not_nil(socket, key, fun) do
    %{assigns: assigns} = socket

    case Map.get(assigns, key, nil) do
      nil ->
        Component.assign(socket, key, fun.(socket))

      _val ->
        socket
    end
  end
end
