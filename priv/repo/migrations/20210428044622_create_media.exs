defmodule Media.Repo.Migrations.CreateMedia do
  use Ecto.Migration


  def change do

    create table(:media) do
      add(:tags, {:array, :string})
      add(:title, :string)
      add(:author, :string)
      add(:type, :string)
      add(:metadata, :map)
      add(:files, {:array, :jsonb}) ## mobile or desktop
      add(:locked_status, :string, default: "locked")
      add(:private_status, :string, default: "private")
      add(:seo_tag, :string)
      add(:namespace, :string)

    timestamps()
    end

    create(index("media", [:namespace]))
  end
end
