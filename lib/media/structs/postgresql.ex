defmodule Media.PostgreSQL do
  @moduledoc false
  alias Media.Cartesian
  alias Media.FiltersPostgreSQL
  alias Media.Helpers
  import Ecto.Query
  defstruct args: []

  defimpl DB, for: Media.PostgreSQL do
    @moduledoc """
    The PostgreSQL context.
    """

    alias Media.{Helpers, Platforms}
    alias Media.Platforms.Platform
    alias Media.PostgreSQL.Schema, as: MediaSchema
    import Ecto.Query, warn: false

    def insert(%{args: attrs}) do
      %MediaSchema{}
      |> MediaSchema.changeset(attrs)
      |> Helpers.repo().insert()
    end

    def update(%{args: %{media: media, params: params}}) do
      media
      |> MediaSchema.update_changeset(params)
      |> Helpers.repo().update()
    end

    @doc """
    Returns the list of medias.

    ## Examples

        iex> list_medias()
        [%{}, ...]

    """

    def list_medias(%{args: args}) do
      case args |> Helpers.build_params() do
        {:error, error} ->
          error

        {:ok, %{filter: filters, sort: sort, operation: operation}} ->
          {offset, limit} =
            Helpers.build_pagination(
              Helpers.extract_param(args, :page),
              Helpers.extract_param(args, :per_page)
            )

          # related_schema = Helpers.env(:content_schema) || Helpers.env(:content_table)

          full_media_query()
          |> FiltersPostgreSQL.init(
            filters |> Cartesian.product(),
            operation
          )
          |> group_by([m], m.id)
          |> add_offset(offset)
          |> add_limit(limit)
          |> add_sort(sort)
          |> Helpers.repo().all()
          |> Enum.map(fn %{files: files, media: media} = args -> format_media(args) end)
      end
    end

    def get_media_by_type(type) do
      Helpers.repo().all(
        MediaSchema,
        from(p in MediaSchema,
          where: p.type == ^type,
          select: p
        )
      )
    end

    def delete_media(%{args: media_id}) do
      from(p in MediaSchema,
        where: p.id == ^media_id
      )
      |> Helpers.repo().delete_all()
    end

    def get_media(%{args: media_id}) do
      case get_full_media(media_id) do
        nil -> {:error, :not_found, "Media does not exist"}
        media -> {:ok, media}
      end
    end

    def get_full_media(id) do
      full_media_query()
      |> where([m], m.id == ^id)
      |> Helpers.repo().one()
      |> case do
        nil ->
          nil

        %{files: _files, media: _media} = args ->
          format_media(args)
      end
    end

    defp format_media(%{media: media, files: files} = args) do
      files =
        files
        |> Enum.map(fn %{"file" => file, "platform" => platform} ->
          Map.put(file, "platform", platform)
        end)

      media
      |> Map.put(:files, files |> Helpers.atomize_keys())
      |> Map.put(:number_of_contents, Map.get(args, :number_of_contents))
    end

    def full_media_query do
      from(m in MediaSchema)
      |> join(
        :inner_lateral,
        [m],
        f in fragment("JSON_ARRAY_ELEMENTS(ARRAY_TO_JSON(?))", m.files),
        on: true
      )
      |> join(:inner, [m, f], p in Media.Platforms.Platform,
        on: fragment("? = (? -> 'platform_id')::TEXT::BIGINT", p.id, f)
      )
      |> join(:left, [m], c in "medias_contents", on: m.id == c.media_id)
      |> select([m, f, p, c], %{
        media: m,
        files: fragment("JSONB_AGG(JSONB_BUILD_OBJECT('platform', ?, 'file', ?))", p, f),
        number_of_contents: count(c.content_id)
      })
      |> group_by([m], m.id)
    end

    def media_and_platform(media_id) do
      from(m in MediaSchema, where: m.id == ^media_id)
    end

    def insert_platform(%{args: args}) do
      Platforms.create_platform(args)
      |> case do
        {:ok, _platform} = res -> res
        error -> error
      end
    end

    def delete_platform(%{args: platform_id}) do
      ## TO DO platform unused implementation
      if platform_unused?(platform_id) do
        from(p in Platform,
          where: p.id == ^platform_id
        )
        |> Helpers.repo().delete_all()
        |> case do
          {1, nil} -> {:ok, "Platform with id #{platform_id} deleted successfully"}
          {0, nil} -> {:error, "Platform does not exist"}
        end
      else
        {:error, "Platform does not exist"}
      end
    end

    def platform_unused?(id) do
      from(m in MediaSchema,
        select: m,
        where:
          fragment(
            "exists (select * from jsonb_to_recordset(unnest(?)) AS specs(platform_id int) where specs.platform_id = ?)",
            m.files,
            ^id
          )
      )
      |> Helpers.repo().all()
    end

    def add_limit(query, 0), do: query

    def add_limit(query, limit) do
      query
      |> limit(^limit)
    end

    def add_offset(query, 0), do: query

    def add_offset(query, offset) do
      query
      |> offset(^offset)
    end

    def add_sort(query, nil), do: query
    def add_sort(query, sort) when sort == %{}, do: query

    def add_sort(query, sort) do
      [field | _tail] = sort |> Map.keys()
      direction = sort[field]

      field =
        cond do
          is_binary(field) -> String.to_atom(field)
          is_atom(field) -> field
          true -> raise "Sorted field can only be an atom or a string"
        end

      with false <- is_nil(direction),
           direction <- direction |> String.downcase() |> String.to_atom(),
           true <- direction in [:desc, :asc] do
        query
        |> order_by([p], [{^direction, field(p, ^field)}])
      else
        _ -> query
      end
    end
  end
end

# from(m in MediaSchema, where: m.id == ^id) |> join(:inner_lateral, [m], f in fragment("JSON_ARRAY_ELEMENTS(ARRAY_TO_JSON(?))", m.files),on: true) |> join(:inner,[m,f], p in Media.Platforms.Platform, on: fragment("? = (? -> 'platform_id')::TEXT::BIGINT", p.id, f))|>select([m, f,p], %{media: m,files: fragment("JSONB_AGG(JSONB_BUILD_OBJECT('platform', ?, 'file', ?))", p, f)})|> group_by([m], m.id)|> Blogs.Repo.one()
