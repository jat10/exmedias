defmodule Media.TestHelpers do
  @moduledoc false

  def clean_mongodb do
    Mongo.delete_many(:mongo, "media", %{})
    Mongo.delete_many(:mongo, "platform", %{})
    :ok
  end
end
