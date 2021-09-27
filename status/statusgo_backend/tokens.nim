import
  json, chronicles, stint, atomics

import
  web3/[ethtypes, conversions], json_serialization

import 
  ./core,
  ../eth/contracts,
  ../types/[setting, network_type, rpc_response]

logScope:
  topics = "wallet"

var
  customTokens {.threadvar.}: seq[Erc20Contract]
  customTokensInited {.threadvar.}: bool
  dirty: Atomic[bool]

dirty.store(true)

proc getCustomTokens*(useCached: bool = true): seq[Erc20Contract] =
  let cacheIsDirty = not customTokensInited or dirty.load
  if useCached and not cacheIsDirty:
    result = customTokens
  else: 
    let payload = %* []
    let responseStr = callPrivateRPC("wallet_getCustomTokens", payload)
    # TODO: this should be handled in the deserialisation of RpcResponse,
    # question has been posed: https://discordapp.com/channels/613988663034118151/616299964242460682/762828178624217109
    let response = RpcResponse(result: $(responseStr.parseJSON()["result"]))
    if not response.error.isNil:
      raise newException(RpcException, "Error getting custom tokens: " & response.error.message)
    result = if response.result == "null": @[] else: Json.decode(response.result, seq[Erc20Contract])
    dirty.store(false)
    customTokens = result
    customTokensInited = true

proc addCustomToken*(address: string, name: string, symbol: string, decimals: int, color: string) =
  let payload = %* [{"address": address, "name": name, "symbol": symbol, "decimals": decimals, "color": color}]
  discard callPrivateRPC("wallet_addCustomToken", payload)
  dirty.store(true)

proc removeCustomToken*(address: string) =
  let payload = %* [address]
  echo callPrivateRPC("wallet_deleteCustomToken", payload)
  dirty.store(true)

proc getTokensBalancesForChainIDs*(chainIds: seq[int], accounts: seq[string], tokens: seq[string]): JsonNode =
  let payload = %* [chainIds, accounts, tokens]
  let response = callPrivateRPC("wallet_getTokensBalancesForChainIDs", payload).parseJson
  if response["result"].kind == JNull:
    return %* {}
  response["result"]
