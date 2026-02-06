defmodule LiveSecret.DoTest do
  use LiveSecret.TenantCase, async: true
  alias LiveSecret.{Secret, Do}

  test "create secret", context do
    tenant = context[:tenant]
    attrs = @valid_presecret_attrs
    changeset = Do.validate_presecret(tenant, attrs)
    assert changeset.valid?
    %Secret{id: id} = Do.insert!(tenant, attrs)
    %Secret{} = Do.get_secret!(tenant, id)
  end

  test "reject invalid secret", context do
    tenant = context[:tenant]
    attrs = @invalid_presecret_attrs
    changeset = Do.validate_presecret(tenant, attrs)
    refute changeset.valid?

    assert_raise(
      FunctionClauseError,
      fn -> Do.insert!(tenant, attrs) end
    )
  end

  test "burn secret", context do
    tenant = context[:tenant]
    secret = Do.insert!(tenant, @valid_presecret_attrs)
    %Secret{iv: nil, content: nil} = Do.burn!(secret)
  end

  test "burn sets burned_at and sensitive data is gone on re-read", context do
    tenant = context[:tenant]
    secret = Do.insert!(tenant, @valid_presecret_attrs)
    assert is_nil(secret.burned_at)
    refute is_nil(secret.content)
    refute is_nil(secret.iv)

    burned = Do.burn!(secret)
    refute is_nil(burned.burned_at)

    # Re-fetch from DB to confirm persistence
    refetched = Do.get_secret!(tenant, secret.id)
    refute is_nil(refetched.burned_at)
    assert is_nil(refetched.content)
    assert is_nil(refetched.iv)
  end

  test "insert! generates unique creator_key per secret", context do
    tenant = context[:tenant]
    s1 = Do.insert!(tenant, @valid_presecret_attrs)
    s2 = Do.insert!(tenant, @valid_presecret_attrs)

    assert is_binary(s1.creator_key)
    assert is_binary(s2.creator_key)
    assert s1.creator_key != s2.creator_key
  end

  test "change live state", context do
    tenant = context[:tenant]
    secret = Do.insert!(tenant, @valid_presecret_attrs)
    %Secret{live?: true} = Do.go_live!(tenant, secret.id)
    %Secret{live?: false} = Do.go_async!(tenant, secret.id)
  end
end
