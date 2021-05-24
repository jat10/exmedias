defmodule Media.Repo.Migrations.CreatePlatform do
  use Ecto.Migration

  def change do
    create table(:platform) do
      add(:description, :string)
      add(:name, :string)
      add(:height, :integer)
      add(:width, :integer)

      timestamps()
    end

    create(unique_index("platform", [:name]))
  end
end
