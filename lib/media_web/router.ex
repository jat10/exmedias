  defmodule Media.Routes do
  @moduledoc """
  Media.Routes must be "used" in your phoenix routes:

  ```elixir
  use Media.Routes, scope: "/admin", pipe_through: [:browser, :authenticate]
  ```

  `:scope` defaults to `"/admin"`

  `:pipe_through` defaults to media's `[:media_browser]`
  """

  # use Phoenix.Router

  defmacro __using__(options \\ []) do
    scoped = Keyword.get(options, :scope, "/admin")
    custom_pipes = Keyword.get(options, :pipe_through, [])
    pipes = [:media_browser] ++ custom_pipes

    quote do
      pipeline :media_browser do
        plug(:accepts, ["html", "json"])
        plug(:fetch_session)
        plug(:fetch_flash)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      scope unquote(scoped), MediaWeb do
        pipe_through(unquote(pipes))

        get("/", PageController, :index, as: :media_home)
        # get("/dashboard", HomeController, :dashboard, as: :media_dashboard)
      end
    end
  end
end
