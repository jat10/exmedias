defmodule Media.Platforms.Platform do
  @moduledoc """
  Platform Schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "platform" do
    field :description, :string
    field :height, :integer
    field :name, :string
    field :width, :integer
    field(:number_of_medias, :integer, virtual: true, default: 0)

    timestamps()
  end

  @doc false
  def changeset(platform, attrs) do
    platform
    |> cast(attrs, [:height, :width, :description, :name])
    |> validate_required([:height, :width, :description, :name])
    |> unique_constraint([:name])
  end
end
