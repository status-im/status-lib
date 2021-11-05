import json, strutils, json_serialization, chronicles
import core
import response_type

import status_go

export response_type

logScope:
  topics = "rpc-general"

proc validateMnemonic*(mnemonic: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  try:
    let response = status_go.validateMnemonic(mnemonic.strip())
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "validateMnemonic", exception=e.msg
    raise newException(RpcException, e.msg)