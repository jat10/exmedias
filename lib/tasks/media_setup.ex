defmodule Mix.Tasks.Media.Setup do
  @moduledoc """
  This command will add all the css, js and migration files to the parent project's priv directory
  """
  def run(_args) do
    dir = Application.app_dir(:media)
    ## we can supply an arg to know if it is a postgresql based project
    if File.dir?("priv/repo/migrations") do
      File.cp_r!("#{dir}/priv/repo/migrations", "priv/repo/migrations")
    end

    ## idempotnent actions
    File.mkdir("priv/static/css")
    File.mkdir("priv/static/js")

    File.copy("#{dir}/priv/static/css/media.css", "priv/static/css/media.css")
    File.copy("#{dir}/priv/static/js/media.js", "priv/static/js/media.js")
  end
end
