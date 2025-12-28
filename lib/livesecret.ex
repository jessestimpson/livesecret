defmodule LiveSecret do
  @moduledoc """
  LiveSecret keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias LiveSecret.{Do, PubSubDo}

  defdelegate count_secrets(tenant), to: Do
  defdelegate get_secret!(tenant, id), to: Do
  defdelegate get_secret(tenant, id), to: Do
  defdelegate insert!(tenant, presecret_attrs), to: Do
  defdelegate update!(changeset), to: Do
  defdelegate validate_presecret(tenant, presecret_attrs), to: Do
  defdelegate burn!(secret), to: Do

  defdelegate go_live!(tenant, id), to: Do
  defdelegate go_async!(tenant, id), to: Do

  defdelegate subscribe!(id), to: PubSubDo
  defdelegate notify_unlocked!(id, user_id), to: PubSubDo
end
