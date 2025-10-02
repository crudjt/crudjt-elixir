defmodule CRUD_JT.Application do
  use Application

  def start(_type, _args) do
    children = []

    CRUD_JT_LRUCache.init_(40_000)

    opts = [strategy: :one_for_one, name: CRUD_JT.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
