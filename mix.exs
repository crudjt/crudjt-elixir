defmodule CRUD_JT.MixProject do
  use Mix.Project

  def project do
    [
      app: :crud_jt,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [crud_jt: []],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CRUD_JT.Application, []} # Вказуємо головний модуль
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.29.0"},
      {:msgpax, "~> 2.4.0"},
      {:cachex, "~> 4.0"}
    ]
  end
end
