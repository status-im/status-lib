import json
import core, utils
import response_type

export response_type

proc getChats*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* []
  result = callPrivateRPC("chats".prefix, payload)