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

  def create(hash, ttl \\ -1, silence_read \\ -1) do
    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)

    __create(bynary_data, size, ttl, silence_read)
  end

  def read(token) do
    str = __read(token)

    if str == "" do
      nil
    else
      Jason.decode!(str)
    end
  end

  def update(token, hash, ttl \\ -1, silence_read \\ -1) do
    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)

    __update(token, bynary_data, size, ttl, silence_read)
  end

  def delete(token) do
    __delete(token)
  end
end
