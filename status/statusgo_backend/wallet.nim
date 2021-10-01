import json, json, options, json_serialization, stint, chronicles
import core, conversions, ../types/[transaction, rpc_response], ../utils, strutils, strformat
from status_go import validateMnemonic#, startWallet
import ../wallet/account
import web3/conversions as web3_conversions, web3/ethtypes


proc getTransfersByAddress*(address: string, toBlock: Uint256, limit: int, loadMore: bool = false): seq[Transaction] =
  try:
    let
      toBlockParsed = "0x" & stint.toHex(toBlock)
      limitParsed = "0x" & limit.toHex.stripLeadingZeros
      transactionsResponse = getTransfersByAddress(address, toBlockParsed, limitParsed, loadMore)
      transactions = parseJson(transactionsResponse)["result"]
    var accountTransactions: seq[Transaction] = @[]

    for transaction in transactions:
      accountTransactions.add(Transaction(
        id: transaction["id"].getStr,
        typeValue: transaction["type"].getStr,
        address: transaction["address"].getStr,
        contract: transaction["contract"].getStr,
        blockNumber: transaction["blockNumber"].getStr,
        blockHash: transaction["blockhash"].getStr,
        timestamp: $hex2LocalDateTime(transaction["timestamp"].getStr()),
        gasPrice: transaction["gasPrice"].getStr,
        gasLimit: transaction["gasLimit"].getStr,
        gasUsed: transaction["gasUsed"].getStr,
        nonce: transaction["nonce"].getStr,
        txStatus: transaction["txStatus"].getStr,
        value: transaction["value"].getStr,
        fromAddress: transaction["from"].getStr,
        to: transaction["to"].getStr
      ))
    return accountTransactions
  except:
    let msg = getCurrentExceptionMsg()
    error "Failed getting wallet account transactions", msg

proc hex2Eth*(input: string): string =
  var value = fromHex(Stuint[256], input)
  result = utils.wei2Eth(value)

proc validateMnemonic*(mnemonic: string): string =
  result = $status_go.validateMnemonic(mnemonic)

proc startWallet*(watchNewBlocks: bool) =
  # this will be fixed in a later PR
  discard

proc hex2Token*(input: string, decimals: int): string =
  var value = fromHex(Stuint[256], input)

  if decimals == 0:
    return fmt"{value}"
  
  var p = u256(10).pow(decimals)
  var i = value.div(p)
  var r = value.mod(p)
  var leading_zeros = "0".repeat(decimals - ($r).len)
  var d = fmt"{leading_zeros}{$r}"
  result = $i
  if(r > 0): result = fmt"{result}.{d}"

proc trackPendingTransaction*(hash: string, fromAddress: string, toAddress: string, trxType: PendingTransactionType, data: string) =
  let payload = %* [{"hash": hash, "from": fromAddress, "to": toAddress, "type": $trxType, "additionalData": data, "data": "",  "value": 0, "timestamp": 0, "gasPrice": 0, "gasLimit": 0}]
  discard callPrivateRPC("wallet_storePendingTransaction", payload)

proc getPendingTransactions*(): string =
  let payload = %* []
  try:
    result = callPrivateRPC("wallet_getPendingTransactions", payload)
  except Exception as e:
    error "Error getting pending transactions (possible dev Infura key)", msg = e.msg
    result = ""


proc getPendingOutboundTransactionsByAddress*(address: string): string =
  let payload = %* [address]
  result = callPrivateRPC("wallet_getPendingOutboundTransactionsByAddress", payload)

proc deletePendingTransaction*(transactionHash: string) =
  let payload = %* [transactionHash]
  discard callPrivateRPC("wallet_deletePendingTransaction", payload)

proc setInitialBlocksRange*(): string =
  let payload = %* []
  result = callPrivateRPC("wallet_setInitialBlocksRange", payload)

proc watchTransaction*(transactionHash: string): string =
  let payload = %* [transactionHash]
  result = callPrivateRPC("wallet_watchTransaction", payload)

proc checkRecentHistory*(addresses: seq[string]): string =
  let payload = %* [addresses]
  result = callPrivateRPC("wallet_checkRecentHistory", payload)

proc getOpenseaCollections*(chainId: int, address: string): string =
  let payload = %* [chainId, address]
  result = callPrivateRPC("wallet_getOpenseaCollectionsByOwner", payload)

proc getOpenseaAssets*(chainId: int, address: string, collectionSlug: string, limit: int): string =
  let payload = %* [chainId, address, collectionSlug, limit]
  result = callPrivateRPC("wallet_getOpenseaAssetsByOwnerAndCollection", payload)

proc fetchCryptoServices*(success: var bool): string =
  success = true
  try:
    result = callPrivateRPC("wallet_getCryptoOnRamps")
  except Exception as e:
    success = false
    error "Error getting crypto services: ", msg = e.msg
    result = ""

proc suggestFees*(): string =
  let payload = %* []
  result = callPrivateRPC("wallet_suggestFees", payload)

proc addSavedAddress*(name, address: string): string =
  let
    payload = %* [{"name": name, "address": address}]
    jsonRaw = callPrivateRPC("wallet_addSavedAddress", payload)
  jsonRaw

proc deleteSavedAddress*(address: string): string =
  let
    payload = %* [address]
    jsonRaw = callPrivateRPC("wallet_deleteSavedAddress", payload)
  jsonRaw

proc getSavedAddresses*(): string =
  let
    payload = %* []
    jsonRaw = callPrivateRPC("wallet_getSavedAddresses", payload)
  jsonRaw
