defmodule Token.TokenService.Server do
  use GRPC.Server, service: Token.TokenService.Service

  @impl true
  def create_token(request, _stream) do
    hash =
      request.packed_data
      |> Msgpax.unpack!()

    ttl = normalize_optional_int(request.ttl)
    silence_read = normalize_optional_int(request.silence_read)

    token =
      CRUDJT.original_create(
        hash,
        ttl,
        silence_read
      )

    %Token.CreateTokenResponse{token: token}
  end

  @impl true
  def read_token(request, _stream) do
    raw_token = request.token

    result_hash =
      CRUDJT.original_read(raw_token)

    {:ok, packed} = Msgpax.pack(result_hash)
    packed_data = IO.iodata_to_binary(packed)

    %Token.ReadTokenResponse{packed_data: packed_data}
  end

  @impl true
  def update_token(request, _stream) do
    raw_token = request.token

    packed_data =
      request.packed_data
      |> Msgpax.unpack!()

    ttl = normalize_optional_int(request.ttl)
    silence_read = normalize_optional_int(request.silence_read)

    result =
      CRUDJT.original_update(
        raw_token,
        packed_data,
        ttl,
        silence_read
      )

    %Token.UpdateTokenResponse{result: result}
  end

  @impl true
  def delete_token(request, _stream) do
    raw_token = request.token

    result =
      CRUDJT.original_delete(raw_token)

    %Token.DeleteTokenResponse{result: result}
  end

  # --- helpers ---

  defp normalize_optional_int(-1), do: nil
  defp normalize_optional_int(value), do: value
end
