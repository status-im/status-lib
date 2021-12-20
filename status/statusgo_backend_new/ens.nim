import json
import ./core, ./response_type

export response_type

proc resolver*(username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  # TODO: Use a real chain id
  let payload = %* [1, username]

  return core.callPrivateRPC("ens_resolver", payload)

proc contentHash*(username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  # TODO: Use a real chain id
  let payload = %* [1, username]

  return core.callPrivateRPC("ens_contentHash", payload)

proc resourceURL*(username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  # TODO: Use a real chain id
  let payload = %* [1, username]
  return core.callPrivateRPC("ens_resourceURL", payload)

