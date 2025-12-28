defmodule LiveSecret.TenantCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.
  """

  use ExUnit.CaseTemplate
  alias Ecto.UUID
  alias EctoFoundationDB.Sandbox
  alias LiveSecret.Repo

  using do
    quote do
      alias LiveSecret.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import LiveSecret.TenantCase

      @valid_presecret_attrs %{
        "burn_key" => "exunit-burnkey",
        "content" => :base64.encode("encrypted-content-here"),
        "iv" => :base64.encode(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1>>),
        "duration" => "1h",
        "mode" => "live",
        "label" => nil
      }

      @preexpired_presecret_attrs %{
        "burn_key" => "exunit-burnkey",
        "content" => :base64.encode("encrypted-content-here"),
        "iv" => :base64.encode(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1>>),
        "duration" => "-1h",
        "mode" => "live",
        "label" => nil
      }

      @invalid_presecret_attrs %{
        "burn_key" => nil,
        "content" => nil,
        "iv" => nil,
        "duration" => nil,
        "mode" => nil,
        "label" => nil
      }
    end
  end

  setup tags do
    setup_sandbox(tags)
  end

  def setup_sandbox(_tags) do
    tenant_id = UUID.autogenerate()
    tenant = Sandbox.checkout(Repo, tenant_id, [])

    on_exit(fn ->
      Sandbox.checkin(Repo, tenant_id)
    end)

    {:ok, [tenant_id: tenant_id, tenant: tenant]}
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
