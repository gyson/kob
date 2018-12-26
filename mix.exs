defmodule Kob.MixProject do
  use Mix.Project

  def project do
    [
      app: :kob,
      version: "0.1.0",
      description: "Another way to compose Plugs",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      name: "Kob",
      source_url: "https://github.com/gyson/kob"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0", only: [:dev]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gyson/kob"}
    }
  end
end
