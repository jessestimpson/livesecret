defmodule LiveSecret.Expiration do
  require Logger

  alias LiveSecret.Do

  def setup_job() do
    config = Application.fetch_env!(:livesecret, LiveSecret.Expiration)
    :timer.apply_interval(config[:interval], LiveSecret.Expiration, :expire_all, [])
  end

  def purge_all() do
    tenant_ids = Do.list_tenants()
    Enum.each(tenant_ids, &open_and_purge/1)
  end

  def expire_all() do
    tenant_ids = Do.list_tenants()
    Enum.each(tenant_ids, &open_and_expire/1)
  end

  def open_and_expire(tenant_id) do
    tenant_id
    |> Do.open_tenant()
    |> expire()
  end

  def open_and_purge(tenant_id) do
    tenant_id
    |> Do.open_tenant()
    |> purge()
  end

  def purge(tenant) do
    expire_before(tenant, ~N[2999-12-31 23:59:59.000])
  end

  def expire(tenant) do
    now = NaiveDateTime.utc_now()
    expire_before(tenant, now)
  end

  def expire_before(tenant, now) do
    {deleted, _} = Do.delete_secrets_expiring_before(tenant, now)

    count_after = LiveSecret.Do.count_secrets(tenant)

    if deleted > 0 or count_after > 0,
      do:
        Logger.info("EXPIRATION before #{inspect(now)} #{deleted} deleted, #{count_after} remain")
  end
end
