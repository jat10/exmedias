defmodule Media.PostgreSQL do
  @moduledoc false

  defstruct args: []

  defimpl DB, for: Media.PostgreSQL do
    @moduledoc """
    The PostgreSQL context.
    """

    alias Media.Helpers
    alias Media.PostgreSQL.Schema, as: Media
    import Ecto.Query, warn: false

    def insert(%{args: attrs}) do
      %Media{}
      |> Media.changeset(attrs)
      |> Helpers.repo().insert()
    end

    @doc """
    Returns the list of medias.

    ## Examples

        iex> list_medias()
        [%{}, ...]

    """

    def update(%{args: %{media: media, params: params}}) do
      media
      |> Media.update_changeset(params)
      |> Helpers.repo().update()
    end

    def list_medias do
      Helpers.repo().all(Media)
    end

    def get_media_by_type(type) do
      Helpers.repo().all(
        Media,
        from(p in Media,
          where: p.type == ^type,
          select: p
        )
      )
    end

    def delete_media(%{args: media_id}) do
      from(p in Media,
        where: p.id == ^media_id
      )
      |> Helpers.repo().delete_all()
    end

    def get(%{args: media_id}) do
      case Helpers.repo().get(Media, media_id) do
        nil -> {:error, :not_found, "Media does not exist"}
        media -> {:ok, media}
      end
    end
  end
end
