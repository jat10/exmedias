defmodule Media.Test.Content do
  @moduledoc """
    This schema is used to mimic the schema content
    on the project that is integrating Medias as a library
  """
  use Ecto.Schema

  schema "content" do
    field(:name, :string)

    timestamps()
  end
end
