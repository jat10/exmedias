defmodule MediaWeb.PlatformController do
  @moduledoc false
  use MediaWeb, :controller
  alias Media.{Context, Helpers}
  action_fallback(MediaWeb.FallbackController)

  def get_platform(conn, %{"id" => id}) do
    case Context.get_platform(id) do
      {:ok, platform} -> render(conn, "platform.json", platform: platform)
      {:error, :not_found, _} = fall_back_error -> fall_back_error
    end
  end

  def list_platforms(conn, args) do
    %{result: platforms, total: total} = Context.list_platforms(args)
    render(conn, "platforms.json", platforms: platforms, total: total)
  end

  def insert_platform(conn, args) do
    case Context.insert_platform(args) do
      {:ok, platform} ->
        render(conn, "platform.json", platform: platform)

      {:error, %Ecto.Changeset{}} = fall_back_error ->
        fall_back_error

      {:error, error} ->
        render(conn |> put_status(400), "error.json", error: error)
    end
  end

  def update_platform(conn, args) do
    case Context.update_platform(args) do
      {:ok, platform} -> render(conn, "platform.json", platform: platform)
      {:error, %Ecto.Changeset{}} = fall_back_error -> fall_back_error
    end
  end

  def delete_platform(conn, %{"id" => id}) do
    case Context.delete_platform(id) do
      {:ok, message} -> render(conn, "message.json", message: message)
      {:error, :not_found, _} = fall_back_error -> fall_back_error
      {:error, error} -> render(conn |> put_status(400), "error.json", error: error)
    end
  end
end
