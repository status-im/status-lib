import json
import core, utils
import response_type

export response_type

proc getJoinedComunities*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* []
  result = callPrivateRPC("joinedCommunities".prefix, payload)

proc getAllCommunities*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("communities".prefix)

proc joinCommunity*(communityId: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("joinCommunity".prefix, %*[communityId])