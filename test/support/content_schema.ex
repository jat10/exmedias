defmodule Media.Test.Content do
  @moduledoc """
    This schema is used to mimic the schema content
    on the project that is integrating Medias as a library
  """
  use Ecto.Schema
  alias Media.Helpers
  alias Media.Test.Content
  import Ecto.Changeset

  schema "content" do
    field(:title, :string)

    many_to_many(
      :medias,
      Media.PostgreSQL.Schema,
      join_through: "medias_contents",
      on_replace: :delete,
      join_keys: [content_id: :id, media_id: :id]
    )

    timestamps()
  end

  def changeset(%Content{} = content, args) do
    content =
      content
      |> cast(args, [:title])

    case Helpers.repo() do
      :mongo ->
        content

      _ ->
        content |> put_assoc(:medias, Map.get(args, :medias))
    end
  end
end
