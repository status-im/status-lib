import json, stint, chronicles, strutils, conversions


import ../types/transaction
import ./core as core

proc checkRecentHistory*(addresses: seq[string]) {.raises: [Exception].} =
  let payload = %* [addresses]
  discard callPrivateRPC("wallet_checkRecentHistory", payload)

proc getTransfersByAddress*(address: string, toBlock: Uint256, limit: int, loadMore: bool = false): RpcResponse[JsonNode] {.raises: [Exception].} =
  let
    toBlockParsed = if not loadMore: newJNull() else: %("0x" & stint.toHex(toBlock))
    limitParsed = "0x" & limit.toHex.stripLeadingZeros
    
  callPrivateRPC("wallet_getTransfersByAddress", %* [address, toBlockParsed, limitParsed, loadMore])
    