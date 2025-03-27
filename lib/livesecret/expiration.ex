defmodule LiveSecret.Expiration do
  require Logger

  alias LiveSecret.Do

  def setup_job() do
    config = Application.fetch_env!(:livesecret, LiveSecret.Expiration)
    :timer.apply_interval(config[:interval], LiveSecret.Expiration, :expire_all_tenants, [])
  end

  def expire_all_tenants() do
    tenant_ids = Do.list_tenants()
    Enum.each(tenant_ids, &open_and_expire/1)
  end

  def open_and_expire(tenant_id) do
    tenant_id
    |> Do.open_tenant()
    |> expire()
  end

  def expire(tenant) do
    now = NaiveDateTime.utc_now()
    expire_before(tenant, now)
  end

  def expire_all(tenant) do
    expire_before(tenant, ~N[2999-12-31 23:59:59.000])
  end

  def expire_before(tenant, now) do
    ids = Do.get_expired_secrets(tenant, now)

    deleted =
      ids
      |> Enum.reduce(
        [],
        fn id, del_acc ->
          case Do.delete_secret(tenant, id) do
            {:ok, _} ->
              [id | del_acc]

            error ->
              Logger.error("EXPIRATION #{id} #{error}")
              del_acc
          end
        end
      )

    count_after = LiveSecret.Do.count_secrets(tenant)

    if length(deleted) > 0 or count_after > 0,
      do:
        Logger.info(
          "EXPIRATION before #{inspect(now)} #{length(deleted)} deleted, #{count_after} remain"
        )
  end
end
