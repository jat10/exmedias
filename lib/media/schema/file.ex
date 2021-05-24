defmodule Media.Schema.File do
  @moduledoc """
    This is the media schema model.
    It represents the media properties and their types.
    ```elixir
    schema "media" do
      field(:tags, {:array, :string})
      field(:title, :string)
      field(:author, :string)
      ## [%{"size"=> 1_000, url=> "http://image.com/image/1", "filename"=> "image/1"}]
      field(:files, {:array, :map})
      field(:type, :string)
      field(:locked_status, :string, default: "locked")
      field(:private_status, :string, dedfault: "private")

      many_to_many Application.get_env(:media, :content_table) |> String.to_atom(),
                 Application.get_env(:media, :content_schema),
                 join_through: "medias_contents"

      timestamps()
  end
  ```elixir
  """
  @fields ~w(url size type filename duration platform_id)a
  use Ecto.Schema
  import Ecto.Changeset
  alias Media.Helpers
  alias Media.Platforms.Platform
  # @derive {Jason.Encoder, only: @fields}
  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:filename, :string)
    field(:type, :string)
    field(:size, :integer)
    field(:duration, :integer)
    belongs_to :platforms, Platform, on_replace: :delete
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, @fields)
    |> validate_required([:type, :filename, :size, :url])
  end

  defp get_platform(nil), do: nil

  defp get_platform(id) do
    Helpers.repo().get(Platform, id)
  end
end
