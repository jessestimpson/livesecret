defmodule LiveSecret.Secret do
  use Ecto.Schema

  alias LiveSecret.{DbId, Secret, OperationalKey}

  @maxcontentsize 4096
  @ivsize 12

  @primary_key {:id, :string, autogenerate: false}
  schema "secrets" do
    field :burn_key, :string, redact: true
    field :burned_at, :naive_datetime, default: nil
    field :content, :binary, redact: true
    field :iv, :binary, redact: true
    field :live?, :boolean, default: true
    field :creator_key, :string, redact: true
    field :expires_at, :naive_datetime
    field :label, :string

    timestamps()
  end

  def new() do
    # In the browser flow, a Secret is always created via Presecret, so
    # expect these values to be overwritten by those attrs
    # (See LiveSecret.Do.insert!)
    #
    # But we do provide all defaults here so that Secret.new always
    # returns a valid struct
    %Secret{
      id: DbId.generate(),
      content: "test",
      creator_key: OperationalKey.generate(),
      expires_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    }
  end

  def topic(id) do
    "secret/#{id}"
  end

  @doc false
  def changeset(secret, attrs) do
    secret
    |> Ecto.Changeset.cast(attrs, [
      :creator_key,
      :burn_key,
      :content,
      :iv,
      :live?,
      :label,
      :burned_at,
      :expires_at
    ])
    |> Ecto.Changeset.validate_required([:creator_key, :live?, :expires_at])
    |> validate_content_size()
    |> validate_iv_size()
  end

  def managing_changeset(secret, attrs \\ %{}) do
    secret
    |> Ecto.Changeset.cast(attrs, [:label])
  end

  def validate_content_size(changeset) do
    validate_byte_size_less_equal(changeset, :content, @maxcontentsize)
  end

  defp validate_byte_size_less_equal(changeset, field, maxsize) do
    changeset
    |> Ecto.Changeset.validate_change(
      field,
      fn ^field, value ->
        if byte_size(value) > maxsize do
          [{field, "too big"}]
        else
          []
        end
      end
    )
  end

  def validate_iv_size(changeset) do
    validate_byte_size_equal(changeset, :iv, @ivsize)
  end

  defp validate_byte_size_equal(changeset, field, size) do
    changeset
    |> Ecto.Changeset.validate_change(
      field,
      fn ^field, value ->
        if byte_size(value) != size do
          [{field, "wrong size"}]
        else
          []
        end
      end
    )
  end
end
