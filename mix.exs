defmodule Minesweeper.Mixfile do
  use Mix.Project

  def project do
    [
      app: :minesweeper,
      version: "0.0.1",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Minesweeper.Application, []},
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
      {:phoenix, "~> 1.4.16"},
      {:phoenix_pubsub, "~> 1.1.2"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.2.1", only: :dev},
      {:gettext, "~> 0.17.1"},
      {:plug_cowboy, "~> 2.1.0"},
      {:phoenix_live_view, "~> 0.11.1"},
      {:poison, "~> 3.1"}
    ]
  end
end
