defmodule Mix.Tasks.Media.Setup do
  @moduledoc """
  This command will add all the css, js and migration files to the parent project's priv directory
  """
  @private_files ["00000000000000_content_for_tests.exs"]
  def run(_args) do
    dir = Application.app_dir(:media)
    ## we can supply an arg to know if it is a postgresql based project
    if File.dir?("priv/repo/migrations") do
      dir_path = Temp.mkdir!("tmp-dir")
      File.cp_r!("#{dir}/priv/repo/migrations", dir_path)

      Enum.each(@private_files, fn file ->
        File.rm!("#{dir_path}/#{file}")
      end)

      File.cp_r!(dir_path, "priv/repo/media_migrations")
    end

    ## idempotnent actions
    File.mkdir("priv/static/css")
    File.mkdir("priv/static/js")

    File.copy("#{dir}/priv/static/css/media.css", "priv/static/css/media.css")
    File.copy("#{dir}/priv/static/js/media.js", "priv/static/js/media.js")
  end
end
