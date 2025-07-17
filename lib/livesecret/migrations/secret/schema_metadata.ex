defmodule LiveSecret.Migrations.Secret.SchemaMetadata do
  use EctoFoundationDB.Migration
  alias LiveSecret.Secret

  def change() do
    [
      create(metadata(Secret))
    ]
  end
end
