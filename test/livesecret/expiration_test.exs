defmodule LiveSecret.ExpirationTest do
  use LiveSecret.TenantCase, async: true

  alias LiveSecret.{Do, Expiration}

  test "everything *can be* expired", context do
    tenant = context[:tenant]
    0 = Do.count_secrets(tenant)
    Do.insert!(tenant, @valid_presecret_attrs)
    1 = Do.count_secrets(tenant)
    Expiration.purge(tenant)
    0 = Do.count_secrets(tenant)
  end

  test "not everything *is* expired", context do
    tenant = context[:tenant]
    0 = Do.count_secrets(tenant)
    Do.insert!(tenant, @preexpired_presecret_attrs)
    Do.insert!(tenant, @valid_presecret_attrs)
    2 = Do.count_secrets(tenant)
    Expiration.expire(tenant)
    1 = Do.count_secrets(tenant)
  end
end
