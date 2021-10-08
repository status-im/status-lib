import json
import core, utils
import response_type

export response_type

proc getJoinedComunities*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* []
  result = callPrivateRPC("joinedCommunities".prefix, payload)