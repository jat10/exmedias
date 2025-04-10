defmodule Media.MixProject do
  use Mix.Project

  def project do
    [
      app: :media,
      version: "0.1.0",
      elixir: "~> 1.14",  # Updated to support newer Elixir versions
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),  # Removed :phoenix compiler as it's deprecated
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      name: "Media",
      docs: [
        # The main page in the docs
        main: "Media",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Media.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},  # Updated to Phoenix 1.7
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},  # Updated
      {:phoenix_live_dashboard, "~> 0.8.0"},  # Updated
      {:telemetry_metrics, "~> 1.0"},  # Updated
      {:telemetry_poller, "~> 1.0"},  # Updated to fix conflict
      {:gettext, "~> 0.22"},  # Updated
      {:jason, "~> 1.4"},  # Updated
      {:plug_cowboy, "~> 2.6"},  # Updated
      {:ex_aws, "~> 2.4"},  # Updated
      {:ex_aws_s3, "~> 2.4"},  # Updated
      {:sweet_xml, "~> 0.7.3"},  # Updated with specific version
      {:elixir_xml_to_map, "~> 2.0"},  # Updated
      {:elixir_uuid, "~> 1.2"},
      {:ex_aws_sts, "~> 2.2"},  # Updated
      {:hackney, "~> 1.18"},  # Updated
      {:sigaws, "~> 0.7"},
      {:httpoison, "~> 2.1", override: true},  # Updated
      {:poison, "~> 5.0"},  # Updated
      {:morphix, "~> 0.8.1"},  # Updated
      {:mongodb_driver, "~> 1.0", hex: :mongodb_driver}, # Replaced mongodb with mongodb_driver
      {:thumbnex, "~> 0.4.0"},  # Updated
      {:temp, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},  # Updated
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},  # Updated
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},  # Updated
      {:excoveralls, "~> 0.16", only: :test},  # Updated
      {:mock, "~> 0.3.7", only: :test},  # Updated
      {:plug_crypto, "~> 1.2"},  # Updated
      {:phoenix_view, "~> 2.0"}  # Added for Phoenix 1.7 compatibility
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.migrate --quiet", "test"]
    ]
  end
end
