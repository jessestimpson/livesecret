defmodule LiveSecret.Presecret do
  use Ecto.Schema

  alias LiveSecret.{OperationalKey, Presecret}

  @modes [:live, :async]
  @durations ["1h", "1d", "3d", "1w"]

  schema "presecrets" do
    field :burn_key, :string, redact: true
    field :content, :string, redact: true
    field :iv, :string, redact: true
    field :mode, Ecto.Enum, values: @modes, default: :live
    field :duration, :string, default: "1h"
    field :label, :string
  end

  def new() do
    %Presecret{
      burn_key: OperationalKey.generate(),
      iv: :base64.encode(:crypto.strong_rand_bytes(12))
    }
  end

  def make_secret_attrs(attrs) do
    changeset =
      %Presecret{}
      |> Ecto.Changeset.cast(attrs, [:burn_key, :content, :iv, :duration, :mode, :label])

    content = changeset |> Ecto.Changeset.get_change(:content) |> decode_base64()
    iv = changeset |> Ecto.Changeset.get_change(:iv) |> decode_base64()
    burn_key = Ecto.Changeset.get_change(changeset, :burn_key)
    mode = Ecto.Changeset.get_change(changeset, :mode)
    duration = Ecto.Changeset.get_change(changeset, :duration)
    label = Ecto.Changeset.get_change(changeset, :label)

    %{
      content: content,
      iv: iv,
      creator_key: OperationalKey.generate(),
      burn_key: burn_key,
      live?: mode == "live",
      label: label,
      expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(), duration_to_seconds(duration))
    }
  end

  defp decode_base64(nil), do: nil
  defp decode_base64(value), do: :base64.decode(value)

  def supported_modes(), do: @modes
  def supported_durations(), do: @durations

  defp duration_to_seconds("-1h"), do: -div(:timer.hours(1), 1000)
  defp duration_to_seconds("1h"), do: div(:timer.hours(1), 1000)
  defp duration_to_seconds("1d"), do: div(:timer.hours(24), 1000)
  defp duration_to_seconds("3d"), do: div(:timer.hours(24) * 3, 1000)
  defp duration_to_seconds("1w"), do: div(:timer.hours(24) * 7, 1000)

  def changeset(presecret, params) do
    presecret
    |> Ecto.Changeset.cast(params, [:burn_key, :content, :iv, :duration, :mode])
    |> Ecto.Changeset.validate_required([:burn_key, :content, :iv, :duration, :mode])
    |> Ecto.Changeset.validate_inclusion(:duration, @durations)
  end
end
