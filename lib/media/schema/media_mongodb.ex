defmodule Media.MongoDB.Schema do
  @moduledoc """
    This is the media schema model.
    It represents the media properties and their types.
    ```elixir
    schema "media" do
      field(:tags, {:array, :string})
      field(:title, :string)
      field(:author, :string)
      field(:contents_used, {:array, :string}) ## the contents using this media
      ## [%{"size"=> 1_000, url=> "http://image.com/image/1", "filename"=> "image/1"}]
      field(:files, {:array, :map})
      field(:type, :string)
      field(:locked_status, :string, default: "locked")
      field(:private_status, :string, dedfault: "private")

      timestamps()
  end
  ```elixir
  """
  @common_metadata ~w(platform url size type filename)a
  @metadata_per_type %{"video" => ~w(duration)a, "podcast" => ~w(duration)a}
  use Ecto.Schema
  import Ecto.Changeset
  @fields ~w(title author contents_used tags type locked_status private_status files)a
  # @derive {Jason.Encoder, only: @fields}
  schema "media" do
    field(:tags, {:array, :string})
    field(:title, :string)
    field(:author, :string)
    field(:contents_used, {:array, :string}, default: [])
    ## [%{"size"=> 1_000, url=> "http://image.com/image/1", "filename"=> "image/1"}]
    field(:files, {:array, :map})
    field(:type, :string)
    field(:locked_status, :string, default: "locked")
    field(:private_status, :string, dedfault: "private")
    ## virtual as this will not be stored in the database but will be returned when querying
    ## so that we have a proper mapping with the schema
    field(:number_of_contents, :integer, virtual: true)

    timestamps()
  end

  @doc """
  In the changeset function, we validate the user's inputs.

  - We make sure ``locked_status`` is included in the values ``locked`` or ``unlocked``, also the ``private_status`` is eirther ``public`` or private``.
  - Both fields ``type`` and ``author`` are required.
  - Media ``type`` can be either ``image``, ``video``, ``document``, ``podcast``
  - Finally we validate the files input based on the type:
    - All the medias should have the following fields: ``platform``, ``size`` (in mb).
    - ``Podcasts`` and ``videos`` also have a ``duration`` field.

  """
  def changeset(media, attrs) do
    media
    |> cast(attrs, @fields)
    |> validate_inclusion(:locked_status, ["locked", "unlocked"])
    |> validate_required(:author)
    |> validate_required(:type)
    |> validate_inclusion(:private_status, ["public", "private"])
    |> validate_inclusion(:type, ["image", "video", "document", "podcast"])
    |> validate_files(attrs |> Map.get(:files) || attrs |> Map.get("files"))

    # changeset
    # |> cast_embed(:files,
    #   with: {Schema, :files_changeset, [get_field(changeset, :type)]}
    # )
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

  # defp mapify(res) when is_struct(res), do: Map.from_struct(res)
  # defp mapify(res), do: res

  defp available_platforms do
    ["desktop", "mobile"]
  end
end
