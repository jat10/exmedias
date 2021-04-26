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
  @common_metadata ~w(platform url size type filename)a
  @metadata_per_type %{"video" => ~w(duration)a, "podcast" => ~w(duration)a}
  use Ecto.Schema
  import Ecto.Changeset
  alias Media.Helpers
  @fields ~w(title author tags type locked_status private_status files)a
  # @derive {Jason.Encoder, only: @fields}
  schema "media" do
    field(:tags, {:array, :string})
    field(:title, :string)
    field(:author, :string)
    field(:files, {:array, :map})
    field(:type, :string)
    field(:locked_status, :string, default: "locked")
    field(:private_status, :string, dedfault: "private")

    many_to_many(
      Helpers.env(:content_table) |> String.to_atom(),
      Helpers.env(:content_schema),
      join_through: "medias_contents",
      join_keys: [media_id: :id, content_id: :id]
    )

    timestamps()
  end

  def changeset(media, attrs) do
    media
    |> cast(attrs, @fields)
    |> validate_inclusion(:locked_status, ["locked", "unlocked"])
    |> validate_required(:author)
    |> validate_required(:type)
    |> validate_inclusion(:private_status, ["public", "private"])
    |> validate_inclusion(:type, ["image", "video", "document", "podcast"])
    |> validate_files(attrs |> Map.get(:files) || attrs |> Map.get("files"))
    |> put_assoc(
      Helpers.env(:content_table) |> String.to_atom(),
      parse_tags(attrs |> Map.get(:articles) || attrs |> Map.get("articles"))
    )
  end

  defp parse_tags(nil), do: nil
  defp parse_tags(params) when params == [], do: nil

  defp parse_tags(params) do
    params
    |> Enum.map(&get_article/1)
    |> Enum.reject(&is_nil/1)
  end

  defp get_article(id) do
    Helpers.repo().get(Helpers.env(:content_schema), id)
  end

  defp validate_files(%Ecto.Changeset{valid?: false} = changeset, _files), do: changeset

  defp validate_files(changeset, files) when is_nil(files), do: changeset

  defp validate_files(changeset, files) when files == [], do: changeset

  defp validate_files(changeset, files) do
    type = changeset |> get_field(:type)

    files
    |> validate_contents(type)
    |> case do
      {:error, error} -> changeset |> add_error(:files, error)
      _files -> changeset
    end
  end

  defp validate_contents(files, type) do
    {_valid, result} =
      files
      |> Enum.reduce(
        {true, []},
        fn
          file, {true, _acc} ->
            {valid, content} = validate_content(file, type)
            {true and valid, content}

          _file, {false, result} ->
            {false, result}
        end
      )

    result
  end

  defp validate_content(file, _type) when file == %{}, do: {:error, "Do not provide empty files"}

  defp validate_content(file, type) when is_map(file) do
    {:ok, file} =
      file
      |> Morphix.atomorphify()

    with {:keys, true} <-
           {:keys,
            file
            |> Map.keys()
            |> Enum.all?(&(&1 in (@common_metadata ++ Map.get(@metadata_per_type, type, []))))},
         {:platforms, true} <- {:platforms, Map.get(file, :platform) in available_platforms()} do
      {true, file}
    else
      {:keys, false} ->
        {false,
         {:error,
          "You provided invalid keys for the files. Please Make sure to provide the supported metadata on files"}}

      {:platforms, false} ->
        {false, {:error, "Invalid Platform, Make sure to provide an existing platform"}}
    end
  end

  defp validate_content(_files, _type),
    do: {:error, "The format of the files sent is not supported, please send a list of files"}

  defp mapify(res) when is_struct(res), do: Map.from_struct(res)
  defp mapify(res), do: res

  defp available_platforms do
    ["desktop", "mobile"]
  end
end
