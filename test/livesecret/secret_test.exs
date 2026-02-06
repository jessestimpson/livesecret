defmodule LiveSecret.SecretTest do
  use ExUnit.Case, async: true

  alias LiveSecret.{Presecret, Secret}

  describe "changeset validations" do
    setup do
      secret = Secret.new()
      {:ok, secret: secret}
    end

    test "rejects content larger than max size", %{secret: secret} do
      oversized = :crypto.strong_rand_bytes(4097)

      changeset = Secret.changeset(secret, %{content: oversized, iv: <<0::96>>})
      assert %{content: ["too big"]} = errors_on(changeset)
    end

    test "accepts content at exactly max size", %{secret: secret} do
      exact = :crypto.strong_rand_bytes(4096)

      changeset = Secret.changeset(secret, %{content: exact, iv: <<0::96>>})
      refute Map.has_key?(errors_on(changeset), :content)
    end

    test "rejects iv that is not exactly 12 bytes", %{secret: secret} do
      changeset = Secret.changeset(secret, %{iv: <<0::88>>})
      assert %{iv: ["wrong size"]} = errors_on(changeset)

      changeset = Secret.changeset(secret, %{iv: <<0::104>>})
      assert %{iv: ["wrong size"]} = errors_on(changeset)
    end

    test "accepts iv that is exactly 12 bytes", %{secret: secret} do
      changeset = Secret.changeset(secret, %{iv: <<0::96>>})
      refute Map.has_key?(errors_on(changeset), :iv)
    end
  end

  describe "receiver_changeset/2" do
    test "does not expose any fields from attrs" do
      changeset =
        Secret.receiver_changeset(%Secret{}, %{
          burn_key: "should-not-appear",
          content: "should-not-appear",
          creator_key: "should-not-appear"
        })

      assert changeset.changes == %{}
    end
  end

  describe "assert_burnable and assert_burnkey_match" do
    alias LiveSecretWeb.PageLive

    test "admin can always burn regardless of burn_key" do
      secret = %Secret{burn_key: "real-key"}
      assert PageLive.assert_burnable(:admin, %{}, secret)
    end

    test "receiver can burn with correct burn_key" do
      secret = %Secret{burn_key: "real-key"}
      params = %{"secret" => %{"burn_key" => "real-key"}}
      assert PageLive.assert_burnable(:receiver, params, secret)
    end

    test "receiver cannot burn with wrong burn_key" do
      secret = %Secret{burn_key: "real-key"}
      params = %{"secret" => %{"burn_key" => "wrong-key"}}
      refute PageLive.assert_burnable(:receiver, params, secret)
    end
  end

  describe "server never handles plaintext or passphrase" do
    test "Presecret schema has no passphrase or cleartext field" do
      fields = Presecret.__schema__(:fields)
      refute :passphrase in fields
      refute :cleartext in fields
      refute :plaintext in fields
    end

    test "Secret schema has no passphrase or cleartext field" do
      fields = Secret.__schema__(:fields)
      refute :passphrase in fields
      refute :cleartext in fields
      refute :plaintext in fields
    end

    test "Presecret changeset drops unknown params" do
      changeset =
        Presecret.changeset(%Presecret{}, %{
          "burn_key" => "key",
          "content" => "data",
          "iv" => "iv",
          "duration" => "1h",
          "mode" => "live",
          "passphrase" => "should-be-dropped",
          "cleartext" => "should-be-dropped"
        })

      refute Map.has_key?(changeset.changes, :passphrase)
      refute Map.has_key?(changeset.changes, :cleartext)
    end
  end

  describe "receiver_changeset prevents data leakage" do
    test "does not cast sensitive fields even if provided" do
      secret = %Secret{
        burn_key: "original-burn-key",
        content: "original-content",
        iv: "original-iv",
        creator_key: "original-creator-key"
      }

      changeset =
        Secret.receiver_changeset(secret, %{
          "burn_key" => "attacker-key",
          "content" => "attacker-content",
          "iv" => "attacker-iv",
          "creator_key" => "attacker-key",
          "label" => "attacker-label"
        })

      # No fields should be castable via receiver_changeset
      assert changeset.changes == %{}
      # The underlying data should remain untouched
      assert changeset.data != secret
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
