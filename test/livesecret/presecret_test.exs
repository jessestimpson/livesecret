defmodule LiveSecret.PresecretTest do
  use ExUnit.Case, async: true

  alias LiveSecret.Presecret

  describe "make_secret_attrs/1" do
    test "decodes base64 content and iv into raw binary" do
      raw_content = "hello world"
      raw_iv = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11>>

      attrs =
        Presecret.make_secret_attrs(%{
          "burn_key" => "test-key",
          "content" => Base.encode64(raw_content),
          "iv" => Base.encode64(raw_iv),
          "duration" => "1h",
          "mode" => "live"
        })

      assert attrs.content == raw_content
      assert attrs.iv == raw_iv
    end

    test "sets live? true for live mode and false for async mode" do
      base_params = %{
        "burn_key" => "test-key",
        "content" => Base.encode64("data"),
        "iv" => Base.encode64(<<0::96>>),
        "duration" => "1h"
      }

      live_attrs = Presecret.make_secret_attrs(Map.put(base_params, "mode", "live"))
      assert live_attrs.live? == true

      async_attrs = Presecret.make_secret_attrs(Map.put(base_params, "mode", "async"))
      assert async_attrs.live? == false
    end

    test "calculates expires_at in the future based on duration" do
      now = NaiveDateTime.utc_now()

      attrs =
        Presecret.make_secret_attrs(%{
          "burn_key" => "test-key",
          "content" => Base.encode64("data"),
          "iv" => Base.encode64(<<0::96>>),
          "duration" => "1d",
          "mode" => "live"
        })

      diff = NaiveDateTime.diff(attrs.expires_at, now, :second)
      # 1 day = 86400 seconds, allow small tolerance for test execution time
      assert_in_delta diff, 86400, 5
    end

    test "generates a creator_key" do
      attrs =
        Presecret.make_secret_attrs(%{
          "burn_key" => "test-key",
          "content" => Base.encode64("data"),
          "iv" => Base.encode64(<<0::96>>),
          "duration" => "1h",
          "mode" => "live"
        })

      assert is_binary(attrs.creator_key)
      assert byte_size(attrs.creator_key) > 0
    end
  end

  describe "changeset/2" do
    test "rejects invalid duration" do
      changeset =
        Presecret.changeset(%Presecret{}, %{
          "burn_key" => "key",
          "content" => "data",
          "iv" => "iv",
          "duration" => "99y",
          "mode" => "live"
        })

      refute changeset.valid?
      assert %{duration: _} = errors_on(changeset)
    end

    test "requires all fields" do
      changeset = Presecret.changeset(%Presecret{}, %{})
      refute changeset.valid?
      errors = errors_on(changeset)
      # mode and duration have schema defaults so they won't appear as errors
      assert %{burn_key: _, content: _, iv: _} = errors
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
