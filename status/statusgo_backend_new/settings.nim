import json
import ./core, ./response_type

export response_type

proc getSettings*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  return core.callPrivateRPC("settings_getSettings")

proc saveSettings*(key: string, value: string | JsonNode | bool | int) {.raises: [Exception].} =
  discard core.callPrivateRPC("settings_saveSetting", %* [key, value])