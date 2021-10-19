import json
import ./core, ./response_type

export response_type

proc getSettings*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  return core.callPrivateRPC("settings_getSettings")