defmodule MediaWeb.PlatformView do
  @moduledoc false
  use MediaWeb, :view
  alias MediaWeb.PlatformView

  def render("platform.json", %{platform: platform}) do
    platform
  end

  def render("message.json", %{message: message}) do
    %{message: message}
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end

  def render("platforms.json", %{platforms: platforms, total: total}) do
    %{result: render_many(platforms, PlatformView, "platform.json"), total: total}
  end
end
