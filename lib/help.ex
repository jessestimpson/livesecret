defmodule Help do
  alias EctoFoundationDB.Tenant

  alias LiveSecret.Repo

  defmacro __using__(_opts) do
    quote do
      alias EctoFoundationDB.Tenant

      alias LiveSecret.Repo
      alias LiveSecret.Secret

      import Ecto.Query
      import Help
    end
  end

  def tenant() do
    case Tenant.list(Repo) do
      [id] ->
        key = {__MODULE__, :tenant, id}

        case :persistent_term.get(key, nil) do
          nil ->
            IO.puts("Opening tenant #{id}")
            tenant = Tenant.open(Repo, id)
            :persistent_term.put(key, tenant)
            tenant

          tenant ->
            tenant
        end

      _ ->
        nil
    end
  end
end
