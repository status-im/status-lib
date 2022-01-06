import json, strutils, strformat
import ./core, ./response_type

export response_type

proc getAccounts*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  return core.callPrivateRPC("eth_accounts")

proc getBlockByNumber*(blockNumber: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [blockNumber, false]
  return core.callPrivateRPC("eth_getBlockByNumber", payload)

proc getEthBalance*(address: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [address, "latest"]
  return core.callPrivateRPC("eth_getBalance", payload)

proc call*(payload = %* []): RpcResponse[JsonNode] {.raises: [Exception].} =
  return core.callPrivateRPC("eth_call", payload)
