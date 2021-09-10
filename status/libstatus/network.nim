import
  json, chronicles, atomics

import json_serialization

from ./core import callPrivateRPC
from ../types/rpc_response import RpcResponseTyped, RpcException
from ../wallet2/network import Network, toPayload

logScope:
  topics = "wallet"

var
  networks {.threadvar.}: seq[Network]
  netowrksInited {.threadvar.}: bool
  dirty: Atomic[bool]

dirty.store(true)

proc getNetworks*(useCached: bool = true): seq[Network] =
  let cacheIsDirty = not netowrksInited or dirty.load
  if useCached and not cacheIsDirty:
    result = networks
  else: 
    let payload = %* [false]
    let responseStr = callPrivateRPC("wallet_getEthereumChains", payload)
    let response = Json.decode(responseStr, RpcResponseTyped[JsonNode])
    if not response.error.isNil:
      raise newException(RpcException, "Error getting networks: " & response.error.message)
    result =  if response.result.isNil or response.result.kind == JNull: @[]
              else: Json.decode($response.result, seq[Network])
    dirty.store(false)
    networks = result
    netowrksInited = true

proc upsertNetwork*(network: Network) =
  discard callPrivateRPC("wallet_addEthereumChain", network.toPayload())
  dirty.store(true)

proc deleteNetwork*(network: Network) =
  let payload = %* [network.chainId]
  discard callPrivateRPC("wallet_deleteEthereumChain", payload)
  dirty.store(true) 