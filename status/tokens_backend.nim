# used to be libstatus, should be merged with tokens
import
  json, chronicles, strformat, stint, strutils, sequtils, tables, atomics

import
  web3/[ethtypes, conversions], json_serialization

import 
  ./libstatus/settings, ./libstatus/core, ./libstatus/wallet, eth/contracts,
  types/[setting, network_type, rpc_response]
from utils import parseAddress

import libstatus/tokens as libstatus_tokens

var
  customTokens {.threadvar.}: seq[Erc20Contract]

proc visibleTokensSNTDefault(): JsonNode =
  let currentNetwork = getCurrentNetwork()
  let SNT = if currentNetwork == NetworkType.Mainnet: "SNT" else: "STT"
  let response = getSetting[string](Setting.VisibleTokens, "{}").parseJSON

  if not response.hasKey($currentNetwork):
    # Set STT/SNT visible by default
    response[$currentNetwork] = %* [SNT]

  return response

proc convertStringSeqToERC20ContractSeq*(stringSeq: seq[string]): seq[Erc20Contract] =
  result = @[]
  for v in stringSeq:
    let t = getErc20Contract(v)
    if t != nil: result.add t
    let ct = customTokens.getErc20ContractBySymbol(v)
    if ct != nil: result.add ct

proc toggleAsset*(symbol: string): seq[Erc20Contract] =
  let currentNetwork = getCurrentNetwork()
  let visibleTokens = visibleTokensSNTDefault()
  var visibleTokenList = visibleTokens[$currentNetwork].to(seq[string])
  let symbolIdx = visibleTokenList.find(symbol)
  if symbolIdx > -1:
    visibleTokenList.del(symbolIdx)
  else:
    visibleTokenList.add symbol
  visibleTokens[$currentNetwork] = newJArray()
  visibleTokens[$currentNetwork] = %* visibleTokenList
  let saved =  saveSetting(Setting.VisibleTokens, $visibleTokens)

  convertStringSeqToERC20ContractSeq(visibleTokenList) 

proc hideAsset*(symbol: string) =
  let currentNetwork = getCurrentNetwork()
  let visibleTokens = visibleTokensSNTDefault()
  var visibleTokenList = visibleTokens[$currentNetwork].to(seq[string])
  var symbolIdx = visibleTokenList.find(symbol)
  if symbolIdx > -1:
    visibleTokenList.del(symbolIdx)
  visibleTokens[$currentNetwork] = newJArray()
  visibleTokens[$currentNetwork] = %* visibleTokenList
  discard saveSetting(Setting.VisibleTokens, $visibleTokens)

proc getVisibleTokens*(): seq[Erc20Contract] =
  let currentNetwork = getCurrentNetwork()
  let visibleTokens = visibleTokensSNTDefault()
  var visibleTokenList = visibleTokens[$currentNetwork].to(seq[string])
  let customTokens = libstatus_tokens.getCustomTokens()

  result = convertStringSeqToERC20ContractSeq(visibleTokenList)

proc getToken*(tokenAddress: string): Erc20Contract =
  getErc20Contracts().concat(libstatus_tokens.getCustomTokens()).getErc20ContractByAddress(tokenAddress.parseAddress)

proc getTokenBalance*(tokenAddress: string, account: string): string = 
  var postfixedAccount: string = account
  postfixedAccount.removePrefix("0x")
  let payload = %* [{
    "to": tokenAddress, "from": account, "data": fmt"0x70a08231000000000000000000000000{postfixedAccount}"
  }, "latest"]
  let response = callPrivateRPC("eth_call", payload)
  let balance = response.parseJson["result"].getStr

  var decimals = 18
  let address = parseAddress(tokenAddress)
  let t = getErc20Contract(address)
  let ct = libstatus_tokens.getCustomTokens().getErc20ContractByAddress(address)
  if t != nil: 
    decimals = t.decimals
  elif ct != nil: 
    decimals = ct.decimals

  result = $hex2Token(balance, decimals)

proc getSNTAddress*(): string =
  let snt = contracts.getSntContract()
  result = $snt.address

proc getSNTBalance*(account: string): string =
  let snt = contracts.getSntContract()
  result = getTokenBalance($snt.address, account)

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
