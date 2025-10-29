defmodule CRUD_JT do
  use Rustler, otp_app: :crudjt, crate: "crudjt"

  defmodule Config do
    @cheatcode "BAGUVIX" # 🐰🥚
    @chosen_cheatcode :chosen_cheatcode

    @enforce_keys [:encrypted_key]
    defstruct encrypted_key: nil, store_jt_path: nil, cheatcode: nil

    def was_started? do
      :persistent_term.get(__MODULE__, false)
    end

    def set_started do
      :persistent_term.put(__MODULE__, true)
    end

    def set_cheatcode(code) do
      :persistent_term.put(@chosen_cheatcode, code)
    end

    def chosen_cheatcode do
      :persistent_term.get(@chosen_cheatcode, nil)
    end

    def hint_cheatcode, do: @cheatcode
  end

  def start_store_jt_config(_encrypted_key, _store_jt_path), do: :erlang.nif_error(:nif_not_loaded)

  def __create(data_pointer, size, ttl, silence_read) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def __read(token), do: :erlang.nif_error(:nif_not_loaded)
  def __update(token, data, size, ttl, silence_read), do: :erlang.nif_error(:nif_not_loaded)
  def __delete(token), do: :erlang.nif_error(:nif_not_loaded)

  def create(hash, ttl \\ nil, silence_read \\ nil) do
    unless Config.was_started? do
      raise CRUD_JT_Validation.error_message(CRUD_JT_Validation.error_not_started)
    end

    silence_read =
      unless CRUD_JT.Config.hint_cheatcode == CRUD_JT.Config.chosen_cheatcode do
        nil
      else
        silence_read
      end

    CRUD_JT_Validation.validate_insertion!(hash, ttl, silence_read)

    ttl = ttl || -1
    silence_read = silence_read || -1

    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)
    CRUD_JT_Validation.validate_hash_bytesize!(size)

    token = __create(bynary_data, size, ttl, silence_read)
    unless token do
      raise CRUD_JT_Errors.InternalError, message: "Something went wrong. Ups"
    end

    CRUD_JT_Cache.insert(token, hash, ttl, silence_read)
    token
  end

  def read(token) do
    unless Config.was_started? do
      raise CRUD_JT_Validation.error_message(CRUD_JT_Validation.error_not_started())
    end

    CRUD_JT_Validation.validate_token!(token)

    case CRUD_JT_Cache.get(token, &__read/1) do
      nil ->
        case __read(token) do
          nil ->
            nil

          str ->
            result = Jason.decode!(str)

            unless result["ok"] do
              error_module =
                Map.get(CRUD_JT_Errors.errors, result["code"], CRUD_JT_Errors.InternalError)

              raise error_module, message: result["error_message"] || "Unknown error"
            end

            case result["data"] do
              nil ->
                nil

              data_str ->
                data = Jason.decode!(data_str)
                CRUD_JT_Cache.force_insert(token, data)
                data
            end
        end

      output ->
        output
    end
  end

  def update(token, hash, ttl \\ nil, silence_read \\ nil) do
    unless Config.was_started? do
      raise CRUD_JT_Validation.error_message(CRUD_JT_Validation.error_not_started)
    end

    silence_read =
      unless CRUD_JT.Config.hint_cheatcode == CRUD_JT.Config.chosen_cheatcode do
        nil
      else
        silence_read
      end

    CRUD_JT_Validation.validate_token!(token)
    CRUD_JT_Validation.validate_insertion!(hash, ttl, silence_read)

    ttl = ttl || -1
    silence_read = silence_read || -1

    {:ok, packed} = Msgpax.pack(hash)
    bynary_data = IO.iodata_to_binary(packed)
    size = byte_size(bynary_data)
    CRUD_JT_Validation.validate_hash_bytesize!(size)

    result = __update(token, bynary_data, size, ttl, silence_read)
    if result do
      CRUD_JT_Cache.insert(token, hash, ttl, silence_read)
    end
    result
  end

  def delete(token) do
    unless Config.was_started? do
      raise CRUD_JT_Validation.error_message(CRUD_JT_Validation.error_not_started)
    end

    CRUD_JT_Validation.validate_token!(token)

    CRUD_JT_Cache.delete(token)
    __delete(token)
  end

  @spec start(Config.t()) :: {:ok, Config.t()} | {:error, String.t()}
  def start(%Config{encrypted_key: nil}), do:
    {:error, CRUD_JT_Validation.error_message(CRUD_JT_Validation.error_encrypted_key_not_set())}

  def start(%Config{} = cfg) do
    CRUD_JT_Validation.validate_encrypted_key!(cfg.encrypted_key)

    response = start_store_jt_config(cfg.encrypted_key, cfg.store_jt_path)

    with {:ok, res} <- Jason.decode(response) do
      if res["ok"] do
        Config.set_started()
        Config.set_cheatcode(cfg.cheatcode)

        if CRUD_JT.Config.hint_cheatcode == CRUD_JT.Config.chosen_cheatcode do
          IO.puts("""
          🐰🥚 You have activated optional param :silence_read for CRUD_JT on method create
          Ideal for one-time reads, email confirmation links, or limits on the number of operations
          Each read decrements :silence_read by 1, when the counter reaches zero — the token is deleted permanently
          """)
        end

        {:ok, cfg}
      else
        case CRUD_JT_Errors.errors()[res["code"]] do
          nil ->
            raise "Unknown error code #{res["code"]}"

          err_mod ->
            raise err_mod, message: res["error_message"]
        end
      end
    else
      _ -> {:error, "Invalid JSON response from start_store_jt_config"}
    end
  end
end
