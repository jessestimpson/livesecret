defmodule LiveSecret.Repo do
  use Ecto.Repo, otp_app: :livesecret, adapter: Ecto.Adapters.FoundationDB
  use EctoFoundationDB.Migrator

  def migrations() do
    [
      {0, LiveSecret.Migrations.Secret.CreateExpiresAtIndex},
      {1, LiveSecret.Migrations.Secret.SchemaMetadata}
    ]
  end
end
