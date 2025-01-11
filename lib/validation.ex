defmodule Validation do
  @u64_max :math.pow(2, 64) - 1 |> trunc()

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
end
