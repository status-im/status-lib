import
  json, chronicles, atomics, uuids

import json_serialization

from ./core import callPrivateRPC
from ../types/rpc_response import RpcResponseTyped, RpcException
from ../types/network import Network, toPayload
import ../types/network_type

import ./settings
import ../types/setting

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


proc toNetwork*(self: NetworkType): Network =
  for network in getNetworks():
    if self.toChainId() == network.chainId:
      return network

  # Will be removed, this is used in case of legacy chain Id
  return Network(chainId: self.toChainId())

proc addNetwork*(name: string, endpoint: string, networkId: int, networkType: string) =
  var networks = settings.getSetting[JsonNode](Setting.Networks_Networks)
  let id = genUUID()
  networks.elems.add(%*{
    "id": $genUUID(),
    "name": name,
    "config": {
      "NetworkId": networkId,
      "DataDir": "/ethereum/" & networkType,
      "UpstreamConfig": {
        "Enabled": true,
        "URL": endpoint
      }
    }
  })
  discard saveSetting(Setting.Networks_Networks, networks)

proc changeNetwork*(network: string) =
  var statusGoResult = setNetwork(network)
  if statusGoResult.error != "":
    error "Error saving updated node config", msg=statusGoResult.error

  # remove all installed sticker packs (pack ids do not match across networks)
  statusGoResult = saveSetting(Setting.Stickers_PacksInstalled, %* {})
  if statusGoResult.error != "":
    error "Error removing all installed sticker packs", msg=statusGoResult.error

  # remove all recent stickers (pack ids do not match across networks)
  statusGoResult = saveSetting(Setting.Stickers_Recent, %* {})
  if statusGoResult.error != "":
    error "Error removing all recent stickers", msg=statusGoResult.error