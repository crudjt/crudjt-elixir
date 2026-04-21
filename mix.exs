defmodule CRUDJT.MixProject do
  use Mix.Project

  def project do
    [
      app: :crudjt,
      version: "1.0.0-beta.3",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [crudjt: []],
      deps: deps(),

      description: description(),
      package: package(),
      docs: [main: "README.md", extras: ["README.md"]],
      source_url: "https://github.com/crudjt/crudjt-elixir",
      homepage_url: "https://github.com/crudjt/crudjt-elixir"
    ]
  end

  defp package do
    [
      files: ["lib", "native", "logos", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Vlad Akymov (v_akymov)"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/crudjt/crudjt-elixir"}
    ]
  end

  defp description do
    """
    Fast B-tree–backed token store for stateful sessions
    """
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CRUDJT.Application, []}
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.29.0"},
      {:msgpax, "~> 2.4.0"},
      {:grpc, "~> 0.9"},
      {:protobuf, "~> 0.12"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
