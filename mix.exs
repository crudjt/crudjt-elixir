defmodule CRUDJT.MixProject do
  use Mix.Project

  def project do
    [
      app: :crudjt,
      version: "1.0.0-beta.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [crudjt: []],
      deps: deps(),

      description: description(),
      package: package(),
      docs: [main: "CRUD JT", extras: ["NET_README_MARKDOWN.md"]]
    ]
  end

  defp package do
    [
      files: ["lib", "native", "priv", "mix.exs", "README*", "NET_README_MARKDOWN*"],
      maintainers: ["Vlad Akymov"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/CRUDJT/CRUDJT-elixir"}
    ]
  end

  defp description do
    """
    Simplifies session. Login / Logout / Authorization
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
      {:protobuf, "~> 0.12"}
    ]
  end
end
