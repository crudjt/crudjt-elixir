defmodule CRUDJT.Application do
  use Application

  def start(_type, _args) do
    children = []

    CRUDJT_LRUCache.init_(40_000)

    opts = [strategy: :one_for_one, name: CRUDJT.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
