defmodule CRUD_JT do
  use Rustler, otp_app: :crud_jt, crate: "crud_jt"

  # Це "заглушка", яка буде замінена на Rust-код
  def encrypted_key(_key), do: :erlang.nif_error(:nif_not_loaded)

  # Проксі-функція для `__create`
  def __create(data_pointer, size, ttl, silence_read) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def __read(token), do: :erlang.nif_error(:nif_not_loaded)
  def __update(token, data, size, ttl, silence_read), do: :erlang.nif_error(:nif_not_loaded)
  def __delete(token), do: :erlang.nif_error(:nif_not_loaded)

  def create(hash, ttl \\ nil, silence_read \\ nil) do
    Validation.validate_insertion!(hash, ttl, silence_read)

    ttl = ttl || -1
    silence_read = silence_read || -1

    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)

    token = __create(bynary_data, size, ttl, silence_read)
    #Cachex.put(:my_cache, token, hash)
    #LRUCache.put(token, hash)
    Cache.insert(token, hash, ttl, silence_read)
    token
  end

  def read(token) do
    Validation.validate_token!(token)

    #{:ok, output} = Cachex.get(:my_cache, token)
    output = Cache.get(token, &__read/1)

    if output do
      output
    else
      str = __read(token)

      if str == "" do
        nil
      else
        hash = Jason.decode!(str)
        Cache.force_insert(token, hash)
        hash
      end
    end
  end

  def update(token, hash, ttl \\ nil, silence_read \\ nil) do
    Validation.validate_token!(token)
    Validation.validate_insertion!(hash, ttl, silence_read)

    ttl = ttl || -1
    silence_read = silence_read || -1

    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)

    result = __update(token, bynary_data, size, ttl, silence_read)
    if result do
      Cache.insert(token, hash, ttl, silence_read)
    end
    result
  end

  def delete(token) do
    Validation.validate_token!(token)

    Cache.delete(token)
    __delete(token)
  end
end
