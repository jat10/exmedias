defmodule Media.Test.Contents do
  @moduledoc """
    This context module is used to mimic the content context
    on the project that is integrating Medias as a library
  """
  alias Media.Helpers
  alias Media.Test.Content

  def create_content(args) do
    Helpers.repo()
    |> create_content(args)
  end

  def create_content(:mongo, args) do
    data = Content.changeset(%Content{}, args)

    {:ok, content} =
      Mongo.insert_one(
        :mongo,
        "content",
        Helpers.get_changes(data) |> Map.delete(:medias)
      )

    Mongo.find_one(:mongo, "content", %{_id: content.inserted_id})
  end

  def create_content(repo, attrs) do
    %Content{}
    |> Content.changeset(attrs)
    |> repo.insert()
  end
end
