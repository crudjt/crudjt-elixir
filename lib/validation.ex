defmodule Validation do
  @u64_max :math.pow(2, 64) - 1 |> trunc()

  @max_hash_size 256

  @error_already_started 0
  @error_not_started 1
  @error_encrypted_key_not_set 2

  def error_already_started, do: @error_already_started
  def error_not_started, do: @error_not_started
  def error_encrypted_key_not_set, do: @error_encrypted_key_not_set

  @error_messages %{
    @error_already_started => "CRUD_JT already started",
    @error_not_started => "CRUD_JT has not started",
    @error_encrypted_key_not_set => "encrypted_key is blank"
  }

  # Повертає повідомлення по коду
  def error_message(code) do
    Map.get(@error_messages, code, "Unknown error (#{code})")
  end

  def validate_insertion!(map, ttl, silence_read) do
    unless is_map(map) do
      raise ArgumentError, message: "Must be a map"
    end

    if ttl && !(ttl > 0 && ttl <= @u64_max) do
      raise ArgumentError, message: "ttl should be greater than 0 and less than 2^64"
    end

    if silence_read && !(silence_read > 0 && silence_read <= @u64_max) do
      raise ArgumentError, message: "silence_read should be greater than 0 and less than 2^64"
    end
  end

  def validate_token!(token) do
    unless is_binary(token) do
      raise ArgumentError, message: "token must be a string"
    end

    if String.length(token) < 1 do
      raise ArgumentError, message: "token cannot be blank"
    end
  end

  # Перевірка розміру хеша
  def validate_hash_bytesize!(hash_bytesize) when hash_bytesize > @max_hash_size do
    raise ArgumentError, "Hash can not be bigger than #{@max_hash_size} bytesize"
  end

  def validate_hash_bytesize!(_hash_bytesize), do: :ok

  # Перевірка encrypted_key (base64 + довжина)
  def validate_encrypted_key!(key) do
    decoded =
      case Base.decode64(key, ignore: false) do
        {:ok, bin} -> bin
        :error -> raise ArgumentError, "'encrypted_key' must be a valid Base64 string"
      end

    unless byte_size(decoded) in [32, 48, 64] do
      raise ArgumentError,
            "'encrypted_key' must be exactly 32, 48, or 64 bytes. Got #{byte_size(decoded)} bytes"
    end

    :ok
  end
end
