defmodule Media.TestHelpers do
  @moduledoc false

  def clean_mongodb do
    Mongo.delete_many(:mongo, "media", %{})
    Mongo.delete_many(:mongo, "platform", %{})
    :ok
  end

  def uuid do
    UUID.uuid4(:hex)
  end

  def set_repo(repo, db) do
    Application.put_env(:media, :repo, repo)
    Application.put_env(:media, :active_database, db)
  end
end
