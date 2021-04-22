defmodule MediaWeb.PageController do
  @moduledoc false
  use MediaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", layout: {MediaWeb.LayoutView, "app.html"})
  end
end
