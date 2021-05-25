defmodule Media.Repo.Migrations.CreateMedia do
  use Ecto.Migration


  def change do
    if Mix.env() == :test do
      create table(:content) do
        add(:title, :string)

      timestamps()
      end
    end

    create table(:media) do
      add(:tags, {:array, :string})
      add(:title, :string)
      add(:author, :string)
      add(:type, :string)
      add(:metadata, :map)
      add(:files, {:array, :jsonb}) ## mobile or desktop
      add(:locked_status, :string, default: "locked")
      add(:private_status, :string, default: "private")

    timestamps()
    end
  end
end
