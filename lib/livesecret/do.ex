defmodule LiveSecret.Do do
  alias LiveSecret.{Repo, Secret, Presecret}
  alias Ecto.Adapters.FoundationDB
  alias EctoFoundationDB.Tenant

  import Ecto.Query

  def list_tenants() do
    Tenant.list(Repo)
  end

  def open_tenant(tenant_id) do
    Tenant.open!(Repo, tenant_id)
  end

  def watch_secret(tenant, label, id) do
    Repo.transaction(
      fn ->
        case Repo.get(Secret, id) do
          nil ->
            {:error, :not_found}

          secret ->
            # workaround for [ecto_foundationdb/#37](https://github.com/ecto-foundationdb/ecto_foundationdb/issues/37)
            secret = FoundationDB.usetenant(secret, tenant)
            {:ok, {secret, Repo.watch(secret, label: label)}}
        end
      end,
      prefix: tenant
    )
  end

  def get_expired_secrets(tenant, now) do
    from(s in Secret,
      where: s.expires_at > ^~N[0000-01-01 00:00:00] and s.expires_at < ^now,
      select: s.id
    )
    |> Repo.all(prefix: tenant)
  end

  def delete_secret(tenant, id) do
    Repo.delete(%Secret{id: id}, prefix: tenant)
  end

  def count_secrets(tenant) do
    Repo.stream(Secret, prefix: tenant)
    |> Enum.count()
  end

  def list_secrets(tenant) do
    Repo.all(Secret, prefix: tenant)
  end

  @doc """
  Reads secret with id or throws
  """
  def get_secret!(tenant, id) do
    Repo.get!(Secret, id, prefix: tenant)
  end

  @doc """
  Reads secret with id or returns error
  """
  def get_secret(tenant, id) do
    Repo.get(Secret, id, prefix: tenant)
  end

  @doc """
  Inserts secret or throws

  `presecret_attrs` is a map of attrs from the Presecret struct. We
  transform this into fields on the Secret. Easier to send base64 to
  to the browser with Presecret and store raw binary in the Secret.
  """
  def insert!(tenant, presecret_attrs) do
    attrs = Presecret.make_secret_attrs(presecret_attrs)

    Secret.new()
    |> FoundationDB.usetenant(tenant)
    |> Secret.changeset(attrs)
    |> Repo.insert!()
  end

  def update!(changeset) do
    Repo.update!(changeset)
  end

  @doc """
  Returns a changeset with validated fields (or not) from Presecret attrs
  """
  def validate_presecret(tenant, presecret_attrs) do
    %Presecret{}
    |> FoundationDB.usetenant(tenant)
    |> Presecret.changeset(presecret_attrs)
    |> Map.put(:action, :validate)
  end

  @doc """
  Burns a secret or throws

  Burned secrets have no iv and no ciphertext
  """
  def burn!(secret) do
    burned_at = NaiveDateTime.utc_now()

    secret
    |> Secret.changeset(%{
      iv: nil,
      burned_at: burned_at,
      content: nil
    })
    |> Repo.update!()
  end

  @doc """
  Updates a secret to be in live mode
  """
  def go_live!(tenant, id) do
    Repo.get!(Secret, id, prefix: tenant)
    |> Secret.changeset(%{
      live?: true
    })
    |> Repo.update!()
  end

  @doc """
  Updates a secret to be in async mode
  """
  def go_async!(tenant, id) do
    Repo.get!(Secret, id, prefix: tenant)
    |> Secret.changeset(%{
      live?: false
    })
    |> Repo.update!()
  end
end
