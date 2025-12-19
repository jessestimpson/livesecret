defmodule LiveSecretWeb.ComponentUtil do
  def render_user_role(:admin, "author"), do: "Admin"
  def render_user_role(:receiver, "author"), do: "Recipient"
  def render_user_role(:admin, "recipient"), do: "Admin Recipient"
  def render_user_role(:receiver, "recipient"), do: "Author"

  def render_admin_unlock_target() do
    "TODO"
  end
end
