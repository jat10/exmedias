defmodule Media.Context do
  @moduledoc """
    The context module defines the functions that should be invoked in the parent app.
    Consider this as the API of Media APP.
  """
  alias Media.Helpers

  @doc """
  Inserts a `media`

  Usage:

  You can insert `media` by calling the following function

  ```elixir
  Media.Context.insert(
    %{
      title: "Media title",
      author: "AUTHOR_ID",
      tags: ["technology"],
      type: "image",
      files: [%{platform: "dekstop", type: "png", size: 2_500}]
      locked_status: "locked",
      private_status: "public",
    }
  )
  ```
  """
  def insert(args) do
    DB.insert(Helpers.db_struct(args))
  end

  @doc """
  Gets a `media`

  Usage:

  You can get a `media` by its id with

  ```elixir
  Media.Context.get(%{id: YOUR_MEDIA_ID})
  ```

  """
  def get(args) do
    DB.get(Helpers.db_struct(args))
  end

  @doc """
  Deletes a media

  You can delete a `media` by its id with

  ```elixir
  Media.Context.delete(%{id: YOUR_MEDIA_ID})
  ```

  """
  def delete(args) do
    DB.delete(Helpers.db_struct(args))
  end

  @doc """
  Updates a `media`

  Usage:

  You can update `media` by calling the following function

  ```elixir
  Media.Context.insert(
    %{
      title: "Media title",
      author: "AUTHOR_ID",
      tags: ["technology"],
      type: "image",
      files: [%{platform: "dekstop", type: "png", size: 2_500}]
      locked_status: "locked",
      private_status: "public",
    }
  )
  ```
  """
  def update(args) do
    DB.update(Helpers.db_struct(args))
  end
end
