# This binding was generated automatically to ensure consistency across languages
# Generated using ChatGPT (GPT-5) from the canonical Ruby SDK
# API is stable and production-ready

defmodule CRUDJT do
  use Rustler, otp_app: :crudjt, crate: "crudjt"

  defmodule Config do
    @grpc_host "127.0.0.1"
    @grpc_port 50051

    @started {__MODULE__, :started}
    @channel {__MODULE__, :channel}
    @master  {__MODULE__, :master}

    def was_started? do
      :persistent_term.get(@started, false)
    end

    def set_started do
      :persistent_term.put(@started, true)
    end

    def set_channel(channel) do
      :persistent_term.put(@channel, channel)
    end

    def channel do
      :persistent_term.get(@channel, nil)
    end

    def set_master(value) do
      :persistent_term.put(@master, value)
    end

    def master do
      :persistent_term.get(@master, false)
    end

    def start_master(opts \\ []) do
      if Config.was_started? do
        raise CRUDJT_Validation.error_message(CRUDJT_Validation.error_already_started())
      end

      secret_key = Keyword.get(opts, :secret_key, nil)
      store_jt_path = Keyword.get(opts, :store_jt_path, nil)

      CRUDJT_Validation.validate_secret_key!(secret_key)

      response = CRUDJT.start_store_jt_config(secret_key, store_jt_path)

      with {:ok, res} <- Jason.decode(response) do
        if res["ok"] do
          CRUDJT_LRUCache.init_(40_000)

          grpc_host = Keyword.get(opts, :grpc_host, @grpc_host)
          grpc_port = Keyword.get(opts, :grpc_port, @grpc_port)

          {:ok, ip} = :inet.parse_address(String.to_charlist(grpc_host))

          GRPC.Server.start(
            Token.TokenService.Server,
            grpc_port,
            adapter_opts: [ip: ip]
          )

          set_master(true)

          Config.set_started

          {:ok}
        else
          case CRUDJT_Errors.errors()[res["code"]] do
            nil ->
              raise "Unknown error code #{res["code"]}"

            err_mod ->
              raise err_mod, message: res["error_message"]
          end
        end
      else
        _ -> {:error, "Invalid JSON response from start_master"}
      end
    end

    def connect_to_master(opts \\ []) do
      if Config.was_started? do
        raise CRUDJT_Validation.error_message(CRUDJT_Validation.error_already_started())
      end

      grpc_host = Keyword.get(opts, :grpc_host, @grpc_host)
      grpc_port = Keyword.get(opts, :grpc_port, @grpc_port)

      {:ok, _sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: GRPC.Client.Supervisor)
      {:ok, channel} = GRPC.Stub.connect("#{grpc_host}:#{grpc_port}")

      set_channel(channel)
      set_master(false)
      set_started()

      channel
    end
  end

  def start_store_jt_config(_secret_key, _store_jt_path), do: :erlang.nif_error(:nif_not_loaded)

  def __create(data_pointer, size, ttl, silence_read) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def __read(token), do: :erlang.nif_error(:nif_not_loaded)
  def __update(token, data, size, ttl, silence_read), do: :erlang.nif_error(:nif_not_loaded)
  def __delete(token), do: :erlang.nif_error(:nif_not_loaded)

  def original_create(hash, ttl \\ nil, silence_read \\ nil) do
    unless Config.was_started? do
      raise CRUDJT_Validation.error_message(CRUDJT_Validation.error_not_started)
    end

    CRUDJT_Validation.validate_insertion!(hash, ttl, silence_read)

    ttl = ttl || -1
    silence_read = silence_read || -1

    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)
    CRUDJT_Validation.validate_hash_bytesize!(size)

    token = __create(bynary_data, size, ttl, silence_read)
    unless token do
      raise CRUDJT_Errors.InternalError, message: "Something went wrong. Ups"
    end

    CRUDJT_Cache.insert(token, hash, ttl, silence_read)
    token
  end

  def create(hash, ttl \\ nil, silence_read \\ nil) do
    if Config.master do
      original_create(hash, ttl, silence_read)
    else
      # token_service.proto expect int64/32 values
      # it sensative for nil and convert it to 0
      # here -1 connverts to 0 for success work CRUDJT_Validation.validate_insertion!
      ttl = normalize(ttl)
      silence_read = normalize(silence_read)

      {:ok, packed} = Msgpax.pack(hash)
      packed_data = IO.iodata_to_binary(packed)
      request =
        %Token.CreateTokenRequest{
          packed_data: packed_data,
          ttl: ttl,
          silence_read: silence_read
        }

      {:ok, response} = Token.TokenService.Stub.create_token(Config.channel, request)

      response.token
    end
  end

  def original_read(token) do
    unless Config.was_started? do
      raise CRUDJT_Validation.error_message(CRUDJT_Validation.error_not_started())
    end

    CRUDJT_Validation.validate_token!(token)

    case CRUDJT_Cache.get(token, &__read/1) do
      nil ->
        case __read(token) do
          nil ->
            nil

          str ->
            result = Jason.decode!(str)

            unless result["ok"] do
              error_module =
                Map.get(CRUDJT_Errors.errors, result["code"], CRUDJT_Errors.InternalError)

              raise error_module, message: result["error_message"] || "Unknown error"
            end

            case result["data"] do
              nil ->
                nil

              data_str ->
                data = Jason.decode!(data_str)
                CRUDJT_Cache.force_insert(token, data)
                data
            end
        end

      output ->
        output
    end
  end

  def read(token) do
    if Config.master do
      original_read(token)
    else
      request =
        %Token.ReadTokenRequest{
          token: token
        }

      {:ok, response} = Token.TokenService.Stub.read_token(Config.channel, request)

      Msgpax.unpack!(response.packed_data)
    end
  end

  def original_update(token, hash, ttl \\ nil, silence_read \\ nil) do
    unless Config.was_started? do
      raise CRUDJT_Validation.error_message(CRUDJT_Validation.error_not_started)
    end

    CRUDJT_Validation.validate_token!(token)
    CRUDJT_Validation.validate_insertion!(hash, ttl, silence_read)

    ttl = ttl || -1
    silence_read = silence_read || -1

    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)
    CRUDJT_Validation.validate_hash_bytesize!(size)

    result = __update(token, bynary_data, size, ttl, silence_read)
    if result do
      CRUDJT_Cache.insert(token, hash, ttl, silence_read)
    end
    result
  end

  def update(token, hash, ttl \\ nil, silence_read \\ nil) do
    if Config.master do
      original_update(token, hash, ttl, silence_read)
    else
      # token_service.proto expect int64/32 values
      # it sensative for nil and convert it to 0
      # here -1 connverts to 0 for success work CRUDJT_Validation.validate_insertion!
      ttl = normalize(ttl)
      silence_read = normalize(silence_read)

      {:ok, packed} = Msgpax.pack(hash)
      packed_data = IO.iodata_to_binary(packed)
      request =
        %Token.UpdateTokenRequest{
          token: token,
          packed_data: packed_data,
          ttl: ttl,
          silence_read: silence_read
        }

      {:ok, response} = Token.TokenService.Stub.update_token(Config.channel, request)

      response.result
    end
  end

  def original_delete(token) do
    unless Config.was_started? do
      raise CRUDJT_Validation.error_message(CRUDJT_Validation.error_not_started)
    end

    CRUDJT_Validation.validate_token!(token)

    CRUDJT_Cache.delete(token)
    __delete(token)
  end

  def delete(token) do
    if Config.master do
      original_delete(token)
    else
      request =
        %Token.DeleteTokenRequest{
          token: token
        }

      {:ok, response} = Token.TokenService.Stub.delete_token(Config.channel, request)

      response.result
    end
  end

  def normalize(nil), do: -1
  def normalize(-1), do: 0
  def normalize(another_value), do: another_value
end
