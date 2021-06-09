defmodule Media.PostgreSQL.Schema do
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
  # @common_metadata ~w(platform_id url size type filename file_id)a
  # @metadata_per_type %{"video" => ~w(duration)a, "podcast" => ~w(duration)a}
  use Ecto.Schema
  import Ecto.Changeset
  alias Media.Helpers
  alias Media.Schema.File
  @fields ~w(title author tags type locked_status private_status seo_tag)a
  @derive {Jason.Encoder,
           only: @fields ++ [:id, :number_of_contents, :files, :updated_at, :inserted_at]}
  schema "media" do
    field(:tags, {:array, :string})
    field(:title, :string)
    field(:author, :string)
    embeds_many(:files, File, on_replace: :delete)
    field(:type, :string)
    field(:locked_status, :string, default: "locked")
    field(:private_status, :string, dedfault: "private")
    field(:seo_tag, :string)

    timestamps()
  end

  def changeset(media, attrs) do
    {changeset, attrs} =
      media
      |> cast(attrs, @fields)
      |> validate_inclusion(:locked_status, ["locked", "unlocked"])
      |> validate_required([:author, :type])
      |> validate_inclusion(:private_status, ["public", "private"])
      |> validate_inclusion(:type, ["image", "video", "document", "podcast"])
      |> Helpers.update_files(attrs)

    changeset = Map.put(changeset, :params, attrs)

    changeset
    |> put_embed(
      :files,
      attrs |> Helpers.extract_param(:files)
    )

    # |> put_assoc(
    #   Helpers.env(:content_table) |> String.to_atom(),
    #   parse_content(
    #     attrs |> Map.get(Helpers.env(:content_table) |> String.to_atom()) ||
    #       attrs |> Map.get(Helpers.env(:content_table))
    #   )
    # )
  end

  # defp parse_content(nil), do: []

  # defp parse_content(params) when params == [], do: nil

  # defp parse_content(params) do
  #   params
  #   |> Enum.map(&get_content/1)
  #   |> Enum.reject(&is_nil/1)
  # end

  # defp get_content(id) do
  #   Helpers.repo().get(Helpers.env(:content_schema), id)
  # end
end
