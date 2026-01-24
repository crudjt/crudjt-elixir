defmodule Token.CreateTokenRequest do
  @moduledoc false

  use Protobuf,
    full_name: "token.CreateTokenRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :packed_data, 1, type: :bytes, json_name: "packedData"
  field :ttl, 2, type: :int64
  field :silence_read, 3, type: :int64, json_name: "silenceRead"
end

defmodule Token.CreateTokenResponse do
  @moduledoc false

  use Protobuf,
    full_name: "token.CreateTokenResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :token, 1, type: :string
end

defmodule Token.ReadTokenRequest do
  @moduledoc false

  use Protobuf,
    full_name: "token.ReadTokenRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :token, 1, type: :string
end

defmodule Token.ReadTokenResponse do
  @moduledoc false

  use Protobuf,
    full_name: "token.ReadTokenResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :packed_data, 1, type: :bytes, json_name: "packedData"
end

defmodule Token.UpdateTokenRequest do
  @moduledoc false

  use Protobuf,
    full_name: "token.UpdateTokenRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :token, 1, type: :string
  field :packed_data, 2, type: :bytes, json_name: "packedData"
  field :ttl, 3, type: :int64
  field :silence_read, 4, type: :int64, json_name: "silenceRead"
end

defmodule Token.UpdateTokenResponse do
  @moduledoc false

  use Protobuf,
    full_name: "token.UpdateTokenResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :result, 1, type: :bool
end

defmodule Token.DeleteTokenRequest do
  @moduledoc false

  use Protobuf,
    full_name: "token.DeleteTokenRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :token, 1, type: :string
end

defmodule Token.DeleteTokenResponse do
  @moduledoc false

  use Protobuf,
    full_name: "token.DeleteTokenResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :result, 1, type: :bool
end

defmodule Token.TokenService.Service do
  @moduledoc false

  use GRPC.Service, name: "token.TokenService", protoc_gen_elixir_version: "0.16.0"

  rpc :CreateToken, Token.CreateTokenRequest, Token.CreateTokenResponse

  rpc :ReadToken, Token.ReadTokenRequest, Token.ReadTokenResponse

  rpc :UpdateToken, Token.UpdateTokenRequest, Token.UpdateTokenResponse

  rpc :DeleteToken, Token.DeleteTokenRequest, Token.DeleteTokenResponse
end

defmodule Token.TokenService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Token.TokenService.Service
end
