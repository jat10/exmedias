defmodule Media.Repo.Migrations.AddSeoTag do
  use Ecto.Migration

  def change do
    alter table(:media) do
      add(:seo_tag, :string)

    end
  end
end
