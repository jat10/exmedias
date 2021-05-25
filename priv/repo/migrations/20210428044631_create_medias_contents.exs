defmodule Media.Repo.Migrations.ContentMediasTable do
  use Ecto.Migration

  def change do
    create table("medias_contents", primary_key: false) do
      add :content_id, references(Application.get_env(:media, :content_table) |> String.to_atom())
      add :media_id, references(:media)
  end

  create(index("medias_contents", [:media_id, :content_id]))

  end
end
