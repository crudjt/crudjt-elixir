defmodule CRUD_JT.Application do
  use Application

  def start(_type, _args) do
    # Визначення дочірніх процесів для supervisor
    children = [
      #{Cachex, name: :my_cache, limit: 40_000},
    ]

    LRUCache.init_(40_000)

    # Параметри для старту супервізора
    opts = [strategy: :one_for_one, name: CRUD_JT.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
