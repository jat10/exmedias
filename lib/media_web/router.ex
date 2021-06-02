defmodule Media.Routes do
  @moduledoc """
  Media.Routes must be "used" in your phoenix routes:

  ```elixir
  use Media.Routes, scope: "/", pipe_through: [:browser, :authenticate]
  ```

  `:scope` defaults to `"/media"`

  `:pipe_through` defaults to media's `[:media_browser]`
  """

  # use Phoenix.Router

  defmacro __using__(options \\ []) do
    scoped = Keyword.get(options, :scope, "/media")
    custom_pipes = Keyword.get(options, :pipe_through, [])
    browser_pipes = [:media_browser] ++ custom_pipes
    api_pipes = [:media_api] ++ custom_pipes

    quote do
      pipeline :media_browser do
        plug(:accepts, ["html", "json"])
        plug(:fetch_session)
        plug(:fetch_flash)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      pipeline :media_api do
        plug(:accepts, ["json"])
      end

      scope unquote(scoped), MediaWeb do
        pipe_through(unquote(browser_pipes))

        get("/", PageController, :index, as: :media)
        # left here for reference
        #  on how to upload media from a form to S3
        post("/upload", PageController, :upload, as: :media)

        # get("/dashboard", HomeController, :dashboard, as: :media_dashboard)
      end

      scope unquote(scoped), MediaWeb do
        pipe_through(unquote(api_pipes))

        post("/platform", PlatformController, :insert_platform, as: :media)
        post("/platforms", PlatformController, :list_platforms, as: :media)
        get("/platform/:id", PlatformController, :get_platform, as: :media)
        put("/platform/:id", PlatformController, :update_platform, as: :media)
        delete("/platform/:id", PlatformController, :delete_platform, as: :media)

        # get("/dashboard", HomeController, :dashboard, as: :media_dashboard)
      end
    end
  end
end
