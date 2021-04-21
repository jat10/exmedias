defmodule Mix.Tasks.Media.Copy do
  @moduledoc """
  This command
  """
  # TODO add the command to also copy the css and js files
  def run(_args) do
    # {:ok, _} = Application.ensure_all_started(:media) |> IO.inspect(label: "STARTED?")
    File.cp_r!(Application.app_dir(:media, "priv/repo/migrations"), "priv/repo/migrations")
    # path = Application.app_dir(:media, "priv/repo/migrations") |> IO.inspect(label: "PATH")

    # Ecto.Migrator.run(Helpers.env(:postgresql_repo), path, :up, all: true) |> IO.inspect(label: "###")
  end
end
