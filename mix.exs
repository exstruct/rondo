defmodule Rondo.Mixfile do
  use Mix.Project

  def project do
    [app: :rondo,
     version: "0.1.0",
     elixir: "~> 1.1",
     description: "component rendering library",
     test_coverage: [tool: ExCoveralls],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ex_json_schema, "~> 0.4.1", optional: true},

     {:mix_test_watch, "~> 0.2", only: :dev},

     {:exprof, "~> 0.2.0", only: test_modes},
     {:excheck, "~> 0.4.1", only: test_modes},
     {:triq, github: "krestenkrab/triq", only: test_modes},
     {:benchfella, "~> 0.3.1", only: test_modes},
     {:excoveralls, "~> 0.5.1", only: test_modes},]
  end

  defp test_modes do
    [:dev, :test, :bench, :profile]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/extruct/rondo"}]
  end
end
