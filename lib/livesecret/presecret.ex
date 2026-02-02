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
    %Presecret{}
    |> Ecto.Changeset.cast(attrs, [:burn_key, :content, :iv, :duration, :mode, :label])
    |> decode_base64(:content)
    |> decode_base64(:iv)
    |> put_creator_key()
    |> convert_mode_to_live()
    |> compute_expires_at()
    |> changeset_to_secret_attrs()
  end

  defp decode_base64(changeset, field) do
    case Ecto.Changeset.get_change(changeset, field) do
      nil -> changeset
      value -> Ecto.Changeset.put_change(changeset, field, :base64.decode(value))
    end
  end

  defp put_creator_key(changeset) do
    Ecto.Changeset.put_change(changeset, :creator_key, OperationalKey.generate())
  end

  defp convert_mode_to_live(changeset) do
    mode = Ecto.Changeset.get_change(changeset, :mode)
    Ecto.Changeset.put_change(changeset, :live?, mode == "live")
  end

  defp compute_expires_at(changeset) do
    duration = Ecto.Changeset.get_change(changeset, :duration)
    now = NaiveDateTime.utc_now()
    expires_at = NaiveDateTime.add(now, duration_to_seconds(duration))
    Ecto.Changeset.put_change(changeset, :expires_at, expires_at)
  end

  defp changeset_to_secret_attrs(changeset) do
    %{
      content: Ecto.Changeset.get_change(changeset, :content),
      iv: Ecto.Changeset.get_change(changeset, :iv),
      creator_key: Ecto.Changeset.get_change(changeset, :creator_key),
      burn_key: Ecto.Changeset.get_change(changeset, :burn_key),
      live?: Ecto.Changeset.get_change(changeset, :live?),
      label: Ecto.Changeset.get_change(changeset, :label),
      expires_at: Ecto.Changeset.get_change(changeset, :expires_at)
    }
  end

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
