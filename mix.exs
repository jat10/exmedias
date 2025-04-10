defmodule Media.MixProject do
  use Mix.Project

  def project do
    [
      app: :media,
      version: "0.1.0",
      elixir: "~> 1.14",  # Compatible with Elixir 1.18
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
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:sweet_xml, "~> 0.7.3"},
      {:elixir_xml_to_map, "~> 2.0"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_aws_sts, "~> 2.2"},
      {:hackney, "~> 1.18"},
      {:sigaws, "~> 0.7"},
      {:httpoison, "~> 2.1"},
      {:poison, "~> 5.0"},
      {:morphix, "~> 0.8.1"},
      {:mongodb_driver, "~> 1.0", hex: :mongodb_driver},
      {:thumbnex, "~> 0.4.0"},
      {:temp, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:excoveralls, "~> 0.16", only: :test},
      {:mock, "~> 0.3.7", only: :test},
      {:plug_crypto, "~> 1.2"},
      {:phoenix_view, "~> 2.0"}
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
