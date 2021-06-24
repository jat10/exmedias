defmodule Media.Repo.Migrations.ContentForTests do
  use Ecto.Migration

  if Mix.env() == :test do
    def change do
      create table(:content) do
        add(:title, :string)

        timestamps()
      end
    end
  end
end
