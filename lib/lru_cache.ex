defmodule LRUCache do
  @moduledoc """
  A module to emulate LRU cache behavior using Cachex.
  """

  alias Cachex

  # Get a value from the cache, updating as necessary
  def get(key, w_func) when is_function(w_func, 1) do
    case Cachex.get(:my_cache, key) do
      {:ok, nil} ->
        nil

      {:ok, cached_value} ->
        # Re-insert to update LRU
        Cachex.put(:my_cache, key, cached_value)

        output = %{}
        output =
          case get_ttl(cached_value) do
            nil -> output
            time_remaining when time_remaining > 0 ->
              Map.put(output, "metadata", %{"ttl" => time_remaining})

            _ ->
              Cachex.del(:my_cache, key)
              nil
          end

        # Якщо silence_read є, зменшуємо його на 1 і оновлюємо кеш
        output =
          case get_silence_read(cached_value) do
            nil -> output
            remaining when remaining > 0 ->
              # Віднімаємо 1 від silence_read
              updated_value = decrement_silence_read(cached_value)
              Cachex.put(:my_cache, key, updated_value)

              Map.update(output, "metadata", %{"silence_read" => remaining - 1}, fn metadata ->
                Map.put(metadata, "silence_read", remaining - 1)
              end)

            _ ->
              Cachex.del(:my_cache, key)
              nil
          end

        if get_silence_read(cached_value) do
          w_func.(key)
        end

        if is_map(output) do
          Map.put(output, "data", cached_value["data"])
        else
          nil
        end

      _ ->
        nil
    end
  end

  # Insert a value into the cache
  def insert(key, value, ttl, silence_read) do
    hash = %{"data" => value}

    hash =
      if ttl > 0 do
        Map.put(hash, "metadata", %{"ttl" => current_time() + ttl})
      else
        hash
      end

    hash =
      if silence_read > 0 do
        Map.update(hash, "metadata", %{"silence_read" => silence_read}, fn metadata ->
          Map.put(metadata, "silence_read", silence_read)
        end)
      else
        hash
      end

    Cachex.put(:my_cache, key, hash)
  end

  # Forcefully insert a value into the cache
  def force_insert(key, value) do
    Cachex.put(:my_cache, key, value)
  end

  # Delete a value from the cache
  def delete(key) do
    Cachex.del(:my_cache, key)
  end

  # Helper: Get `ttl` expiration time
  defp get_ttl(cached_value) do
    cached_value
    |> Map.get("metadata", %{})
    |> Map.get("ttl")
    |> then(fn
      nil -> nil
      expiration -> expiration - current_time()
    end)
  end

  # Helper: Get `silence_read` count
  defp get_silence_read(cached_value) do
    cached_value
    |> Map.get("metadata", %{})
    |> Map.get("silence_read")
  end

  # Helper: Decrement `silence_read` count
  defp decrement_silence_read(cached_value) do
    cached_value
    |> Map.update!("metadata", fn metadata ->
      Map.update!(metadata, "silence_read", &(&1 - 1))
    end)
  end

  # Helper: Get current time in seconds
  defp current_time do
    DateTime.utc_now()
    |> DateTime.to_unix(:second)
  end
end
