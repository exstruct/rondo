defmodule Rondo.Mixfile do
  use Mix.Project

  def project do
    [app: :rondo,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: "",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "bench": :bench,
       "coveralls": :test,
       "coveralls.circle": :test,
       "coveralls.detail": :test,
       "coveralls.html": :test
     ],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: !(Mix.env in [:dev, :test]),
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:excheck, "~> 0.4.1", only: [:dev, :test, :bench]},
     {:triq, github: "krestenkrab/triq", only: [:dev, :test, :bench]},
     {:benchfella, "~> 0.3.1", only: [:dev, :test, :bench]},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:excoveralls, "~> 0.5.1", only: :test},]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/extruct/rondo"}]
  end
end
