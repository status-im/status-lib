import json
import core
import response_type

export response_type

proc saveMailserver*(id: string, name: string, enode: string, fleet: string): 
  RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [{
      "id": id,
      "name": name,
      "address": enode,
      "fleet": fleet
    }]
  result = callPrivateRPC("mailservers_addMailserver", payload)

proc getMailservers*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("mailservers_getMailservers")