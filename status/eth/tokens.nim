# used to be statusgo_backend, should be merged with tokens
import
  json, chronicles, strformat, stint, strutils, sequtils, tables, atomics

import
  web3/[ethtypes, conversions], json_serialization

import 
  ../statusgo_backend/[core, wallet, settings],
  ../statusgo_backend/tokens as statusgo_backend_tokens,
  ../types/[setting, network, rpc_response],
  ./contracts
from ../utils import parseAddress

var
  customTokens {.threadvar.}: seq[Erc20Contract]

proc visibleTokensSNTDefault(network: Network): JsonNode =
  let symbol = network.sntSymbol()
  let response = getSetting[string](Setting.VisibleTokens, "{}").parseJSON

  if not response.hasKey($network.chainId):
    # Set STT/SNT visible by default
    response[$network.chainId] = %* [symbol]

  return response

proc convertStringSeqToERC20ContractSeq*(network: Network, stringSeq: seq[string]): seq[Erc20Contract] =
  result = @[]
  for v in stringSeq:
    let t = findErc20Contract(network.chainId, v)
    if t != nil: result.add t
    let ct = customTokens.findBySymbol(v)
    if ct != nil: result.add ct

proc toggleAsset*(network: Network, symbol: string): seq[Erc20Contract] =
  let visibleTokens = visibleTokensSNTDefault(network)
  var visibleTokenList = visibleTokens[$network.chainId].to(seq[string])
  let symbolIdx = visibleTokenList.find(symbol)
  if symbolIdx > -1:
    visibleTokenList.del(symbolIdx)
  else:
    visibleTokenList.add symbol
  visibleTokens[$network.chainId] = newJArray()
  visibleTokens[$network.chainId] = %* visibleTokenList
  let saved = saveSetting(Setting.VisibleTokens, $visibleTokens)

  convertStringSeqToERC20ContractSeq(network, visibleTokenList) 

proc hideAsset*(network: Network, symbol: string) =
  let visibleTokens = visibleTokensSNTDefault(network)
  var visibleTokenList = visibleTokens[$network.chainId].to(seq[string])
  var symbolIdx = visibleTokenList.find(symbol)
  if symbolIdx > -1:
    visibleTokenList.del(symbolIdx)
  visibleTokens[$network.chainId] = newJArray()
  visibleTokens[$network.chainId] = %* visibleTokenList
  discard saveSetting(Setting.VisibleTokens, $visibleTokens)

proc getVisibleTokens*(network: Network): seq[Erc20Contract] =
  let visibleTokens = visibleTokensSNTDefault(network)
  var visibleTokenList = visibleTokens[$network.chainId].to(seq[string])
  let customTokens = statusgo_backend_tokens.getCustomTokens()

  result = convertStringSeqToERC20ContractSeq(network, visibleTokenList)

proc getToken*(network: Network, tokenAddress: string): Erc20Contract =
  allErc20ContractsByChainId(network.chainId).concat(statusgo_backend_tokens.getCustomTokens()).findByAddress(tokenAddress.parseAddress)

proc getTokenBalance*(network: Network, tokenAddress: string, account: string): string = 
  var postfixedAccount: string = account
  postfixedAccount.removePrefix("0x")
  let payload = %* [{
    "to": tokenAddress, "from": account, "data": fmt"0x70a08231000000000000000000000000{postfixedAccount}"
  }, "latest"]
  let response = callPrivateRPC("eth_call", payload)
  let balance = response.parseJson["result"].getStr

  var decimals = 18
  let address = parseAddress(tokenAddress)
  let t = findErc20Contract(network.chainId, address)
  let ct = statusgo_backend_tokens.getCustomTokens().findByAddress(address)
  if t != nil: 
    decimals = t.decimals
  elif ct != nil: 
    decimals = ct.decimals

  result = $hex2Token(balance, decimals)

proc getSNTAddress*(network: Network): string =
  let contract = findErc20Contract(network.chainId, network.sntSymbol)
  return $contract.address

proc getSNTBalance*(network: Network, account: string): string =
  result = getTokenBalance(network, getSNTAddress(network), account)

proc getTokenString*(contract: Contract, methodName: string): string =
  let payload = %* [{
      "to": $contract.address,
      "data": contract.methods[methodName].encodeAbi()
    }, "latest"]
  
  let responseStr = callPrivateRPC("eth_call", payload)
  let response = Json.decode(responseStr, RpcResponse)
  if not response.error.isNil:
    raise newException(RpcException, "Error getting token string - " & methodName & ": " & response.error.message)
  if response.result == "0x":
    return ""

  let size = fromHex(Stuint[256], response.result[66..129]).truncate(int)
  result = response.result[130..129+size*2].parseHexStr

proc tokenName*(contract: Contract): string = getTokenString(contract, "name")

proc tokenSymbol*(contract: Contract): string = getTokenString(contract, "symbol")

proc tokenDecimals*(contract: Contract): int =
  let payload = %* [{
      "to": $contract.address,
      "data": contract.methods["decimals"].encodeAbi()
    }, "latest"]
  
  let responseStr = callPrivateRPC("eth_call", payload)
  let response = Json.decode(responseStr, RpcResponse)
  if not response.error.isNil:
    raise newException(RpcException, "Error getting token decimals: " & response.error.message)
  if response.result == "0x":
    return 0
  result = parseHexInt(response.result)
