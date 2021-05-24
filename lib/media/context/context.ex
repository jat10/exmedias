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
      files: [%{platform_id: "dekstop", type: "png", size: 2_500}],
      locked_status: "locked",
      private_status: "public",
    }
  )
  ```
  """
  def insert_media(args) do
    DB.insert_media(Helpers.db_struct(args))
  end

  @doc """
  Gets a `media`

  Usage:

  You can get a `media` by its id with

  ```elixir
  Media.Context.get(%{id: YOUR_MEDIA_ID})
  ```

  """
  def get_media(args) do
    DB.get_media(Helpers.db_struct(args))
  end

  def list_medias(args \\ %{}) do
    DB.list_medias(Helpers.db_struct(args))
  end

  @doc """
  Deletes a media

  You can delete a `media` by its id with

  ```elixir
  Media.Context.delete(%{id: YOUR_MEDIA_ID})
  ```

  """
  def delete_media(args) do
    DB.delete_media(Helpers.db_struct(args))
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
      files: [%{platform_id: 1, type: "png", size: 2_500}],
      locked_status: "locked",
      private_status: "public",
    }
  )
  ```
  """
  def update_media(args) do
    DB.update_media(Helpers.db_struct(args))
  end

  def insert_platform(args) do
    DB.insert_platform(Helpers.db_struct(args))
  end

  def get_platform(args) do
    DB.get_platform(Helpers.db_struct(args))
  end

  def update_platform(args) do
    DB.update_platform(Helpers.db_struct(args))
  end

  def delete_platform(args) do
    DB.delete_platform(Helpers.db_struct(args))
  end
end
