defmodule Cache do
  def get(key, read_func) do
    case LRUCache.get(key) do
      -1 -> nil
      cached_token -> process_cached_token(key, cached_token, read_func, %{})
    end
  end

  def insert(key, token, ttl, silence_read) do
    hash = %{"data" => token}

    # Додаємо параметр ttl, якщо він більший за 0
    hash =
      if ttl > 0 do
        Map.put(hash, "metadata", %{"ttl" => :os.system_time(:seconds) + ttl})
      else
        hash
      end

    # Додаємо параметр silence_read, якщо він більший за 0
    hash =
      if silence_read > 0 do
        Map.update(hash, "metadata", %{"silence_read" => silence_read}, fn y ->
          Map.put(y, "silence_read", silence_read)
        end)
      else
        hash
      end

    LRUCache.put(key, hash)
  end

  def delete(key) do
    LRUCache.del(key)
  end

  def force_insert(key, hash) do
    LRUCache.put(key, hash)
  end

  defp process_cached_token(key, cached_token, read_func, output) do
    # Отримуємо або ініціалізуємо metadata
    metadata = Map.get(cached_token, "metadata", %{})

    # Оновлюємо ttl
    current_time = :os.system_time(:seconds)
    metadata =
      case Map.get(metadata, "ttl") do
        nil -> metadata
        ttl ->
          time_diff = ttl - current_time
          if time_diff <= 0 do
            LRUCache.del(key)
            #Map.delete(metadata, "ttl")
            :was_deleted
          else
            Map.put(metadata, "ttl", time_diff)
          end
      end

    # Оновлюємо silence_read
    if metadata == :was_deleted do
      nil
    else
      metadata =
        case Map.get(metadata, "silence_read") do
          nil -> metadata
          silence_read ->
            updated_silence_read = silence_read - 1
            if updated_silence_read <= 0 do
              LRUCache.del(key)
              #Map.delete(metadata, "silence_read")
              :was_deleted
            else
              read_func.(key)
              updated_metadata = Map.put(metadata, "silence_read", updated_silence_read)

              cached_metadata = LRUCache.get(key)["metadata"]
              cached_metadata = Map.put(cached_metadata, "silence_read", updated_silence_read)

              LRUCache.put(key, Map.put(cached_token, "metadata", cached_metadata))

              updated_metadata
            end
        end

        #IO.puts(metadata)

        # Формуємо кінцевий результат
        if metadata == :was_deleted do
          nil
        else
          output =
            if metadata != nil and metadata != %{} do
              output
              |> Map.put("metadata", metadata)
            else
              output
            end
            |> Map.put("data", Map.get(cached_token, "data"))
        end
      end
    end
end
