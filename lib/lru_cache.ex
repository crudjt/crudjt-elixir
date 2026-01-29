defmodule CRUDJT_LRUCache do
  alias :persistent_term, as: PersistentTerm
  alias :ets, as: Ets

  @capacity_key {:crudjt_lru_cache, :capacity}
  @cache_table :crudjt_lru_cache
  @ttl_table :crudjt_lru_cache_ttl

  @spec init_(capacity :: integer) :: any
  def init_(capacity) do
    PersistentTerm.put(@capacity_key, capacity)

    if Enum.member?(Ets.all(), @cache_table) == false do
      Ets.new(@cache_table, [:set, :public, :named_table])
      Ets.new(@ttl_table, [:ordered_set, :public, :named_table])
    else
      Ets.delete_all_objects(@cache_table)
      Ets.delete_all_objects(@ttl_table)
    end
    :ok
  end

  @spec get(key :: integer) :: integer
  def get(key) do
    with {key, value} <- extract(key) do
      insert(key, value)
      value
    end
  end

  @spec put(key :: integer, value :: integer) :: any
  def put(key, value) do
    extract(key)
    insert(key, value)
    evict()
  end

  @spec del(key :: integer) :: :ok | :error
  def del(key) do
    case Ets.lookup(@cache_table, key) do
      [{_, uniq, _value}] ->
        # Видаляємо записи з обох таблиць
        Ets.delete(@cache_table, key)
        Ets.delete(@ttl_table, uniq)
        :ok

      [] ->
        :error
    end
  end


  defp insert(key, value, uniq \\ uniq()) do
    Ets.insert(@cache_table, {key, uniq, value})
    Ets.insert(@ttl_table, {uniq, key})
  end

  defp evict() do
    if Ets.info(@cache_table, :size) > PersistentTerm.get(@capacity_key) do
      uniq = Ets.first(@ttl_table)
      [{_, key}] = Ets.lookup(@ttl_table, uniq)
      Ets.delete(@ttl_table, uniq)
      Ets.delete(@cache_table, key)
    end
  end

  defp extract(key) do
    case Ets.lookup(@cache_table, key) do
      [{_,uniq, value}] ->
        Ets.delete(@ttl_table, uniq)
        {key, value}
      [] ->
        -1
    end
  end

  defp uniq do
    :erlang.unique_integer([:monotonic])
  end
end
