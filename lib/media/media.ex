defmodule Media.Schema do
  @moduledoc """
    This is the media schema model.
    It represents the media properties and their types.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(title author tracker tags type metadata)a
  # @derive {Jason.Encoder, only: @fields}
  schema "media" do
    field(:tags, {:array, :string})
    field(:title, :string)
    field(:author, :string)
    field(:tracker, :integer)
    field(:type, :string)
    field(:metadata, :map)
    # field(:required_fields, {:array, :string})

    timestamps()
  end

  def changeset(media, attrs) do
    media
    |> cast(attrs, @fields)
  end
end
