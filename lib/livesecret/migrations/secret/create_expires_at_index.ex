defmodule LiveSecret.Migrations.Secret.CreateExpiresAtIndex do
  use EctoFoundationDB.Migration
  alias LiveSecret.Secret

  def change() do
    [
      create(index(Secret, [:expires_at]))
    ]
  end
end
