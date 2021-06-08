defmodule MediaWeb.MediaController do
  @moduledoc false
  use MediaWeb, :controller
  alias Media.{Context, Helpers}
  action_fallback(MediaWeb.FallbackController)

  def get_media(conn, %{"id" => id}) do
    case Context.get_media(id) do
      {:ok, media} -> render(conn, "media.json", media: media)
      {:error, :not_found, _} = fall_back_error -> fall_back_error
    end
  end

  def list_medias(conn, args) do
    %{result: medias, total: total} = Context.list_medias(args)
    render(conn, "medias.json", medias: medias, total: total)
  end

  def insert_media(conn, args) do
    case Context.insert_media(args) do
      {:ok, media} ->
        render(conn, "media.json", media: media)

      {:error, %Ecto.Changeset{}} = fall_back_error ->
        fall_back_error

      {:error, error} ->
        render(conn |> put_status(400), "error.json", error: error)
    end
  end

  def update_media(conn, %{"id" => id} = args) do
    case Context.update_media(args |> Helpers.atomize_keys()) do
      {:ok, media} ->
        render(conn, "media.json", media: media)

      {:error, %Ecto.Changeset{}} = fall_back_error ->
        fall_back_error
    end
  end

  def update_media(conn, _args),
    do: render(conn, "error.json", error: "Please provide an Id to update a media")

  def delete_media(conn, %{"id" => id}) do
    case Context.delete_media(id) do
      {:ok, message} -> render(conn, "message.json", message: message)
      {:error, :not_found, _} = fall_back_error -> fall_back_error
      {:error, error} -> render(conn |> put_status(400), "error.json", error: error)
    end
  end
end
