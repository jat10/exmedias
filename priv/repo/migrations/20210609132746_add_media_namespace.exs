defmodule Media.Repo.Migrations.AddMediaNamespace do
  use Ecto.Migration

  def change do
    alter table(:media) do
      add(:namespace, :string)
    end

    create(index("media", [:namespace]))

  end
end
