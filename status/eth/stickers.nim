# used to be statusgo_backend, should be merged with stickers

import # std libs
  atomics, json, tables, sequtils, httpclient, net,
  json, json_serialization, chronicles, web3/ethtypes,
  stint, strutils
from strutils import parseHexInt, parseInt
import nbaser

import # vendor libs
  json_serialization, chronicles, libp2p/[multihash, multicodec, cid], stint,
  web3/[ethtypes, conversions]
from nimcrypto import fromHex

import # status-desktop libs
  ../types/[sticker, setting, rpc_response, network_type], 
  ../statusgo_backend/[edn_helpers, settings], 
  ../utils,
  ./transactions as transactions, 
  ./contracts

# Retrieves number of sticker packs owned by user
# See https://notes.status.im/Q-sQmQbpTOOWCQcYiXtf5g#Read-Sticker-Packs-owned-by-a-user
# for more details
proc getBalance*(chainId: int, address: Address): int =
  let contract = contracts.findContract(chainId, "sticker-pack")
  if contract == nil: return 0

  let
    balanceOf = BalanceOf(address: address)
    payload = %* [{
      "to": $contract.address,
      "data": contract.methods["balanceOf"].encodeAbi(balanceOf)
    }, "latest"]

  let response = transactions.eth_call(payload)

  if not response.error.isNil:
    raise newException(RpcException, "Error getting stickers balance: " & response.error.message)
  if response.result == "0x":
    return 0
  result = parseHexInt(response.result)

# Gets number of sticker packs
proc getPackCount*(chainId: int): int =
  let contract = contracts.findContract(chainId, "stickers")
  if contract == nil: return 0

  let payload = %* [{
      "to": $contract.address,
      "data": contract.methods["packCount"].encodeAbi()
    }, "latest"]

  let response = transactions.eth_call(payload)

  if not response.error.isNil:
    raise newException(RpcException, "Error getting stickers balance: " & response.error.message)
  if response.result == "0x":
    return 0
  result = parseHexInt(response.result)

# Gets sticker pack data
proc getPackData*(chainId: int, id: Stuint[256], running: var Atomic[bool]): StickerPack =
  let secureSSLContext = newContext()
  let client = newHttpClient(sslContext = secureSSLContext)
  try:
    let
      contract = contracts.findContract(chainId, "stickers")
      contractMethod = contract.methods["getPackData"]
      getPackData = GetPackData(packId: id)
      payload = %* [{
        "to": $contract.address,
        "data": contractMethod.encodeAbi(getPackData)
        }, "latest"]
    let response = transactions.eth_call(payload)
    if not response.error.isNil:
      raise newException(RpcException, "Error getting sticker pack data: " & response.error.message)

    let packData = contracts.decodeContractResponse[PackData](response.result)

    if not running.load():
      trace "Sticker pack task interrupted, exiting sticker pack loading"
      return

    # contract response includes a contenthash, which needs to be decoded to reveal
    # an IPFS identifier. Once decoded, download the content from IPFS. This content
    # is in EDN format, ie https://ipfs.infura.io/ipfs/QmWVVLwVKCwkVNjYJrRzQWREVvEk917PhbHYAUhA1gECTM
    # and it also needs to be decoded in to a nim type
    let contentHash = contracts.toHex(packData.contentHash)
    let url = "https://ipfs.infura.io/ipfs/" & decodeContentHash(contentHash)
    var ednMeta = client.getContent(url)

    # decode the EDN content in to a StickerPack
    result = edn_helpers.decode[StickerPack](ednMeta)
    # EDN doesn't include a packId for each sticker, so add it here
    result.stickers.apply(proc(sticker: var Sticker) =
      sticker.packId = truncate(id, int))
    result.id = truncate(id, int)
    result.price = packData.price
  except Exception as e:
    raise newException(RpcException, "Error getting sticker pack data: " & e.msg)
  finally:
    client.close()

proc tokenOfOwnerByIndex*(chainId: int, address: Address, idx: Stuint[256]): int =
  let
    contract = contracts.findContract(chainId, "sticker-pack")
    tokenOfOwnerByIndex = TokenOfOwnerByIndex(address: address, index: idx)
    payload = %* [{
      "to": $contract.address,
      "data": contract.methods["tokenOfOwnerByIndex"].encodeAbi(tokenOfOwnerByIndex)
    }, "latest"]

  let response = transactions.eth_call(payload)
  if not response.error.isNil:
    raise newException(RpcException, "Error getting owned tokens: " & response.error.message)
  if response.result == "0x":
    return 0
  result = parseHexInt(response.result)

proc getPackIdFromTokenId*(chainId: int, tokenId: Stuint[256]): int =
  let
    contract = contracts.findContract(chainId, "sticker-pack")
    tokenPackId = TokenPackId(tokenId: tokenId)
    payload = %* [{
      "to": $contract.address,
      "data": contract.methods["tokenPackId"].encodeAbi(tokenPackId)
    }, "latest"]

  let response = transactions.eth_call(payload)
  if not response.error.isNil:
    raise newException(RpcException, "Error getting pack id from token id: " & response.error.message)
  if response.result == "0x":
    return 0
  result = parseHexInt(response.result)

proc saveInstalledStickerPacks*(installedStickerPacks: Table[int, StickerPack]) =
  let json = %* {}
  for packId, pack in installedStickerPacks.pairs:
    json[$packId] = %(pack)
  discard settings.saveSetting(Setting.Stickers_PacksInstalled, $json)

proc saveRecentStickers*(stickers: seq[Sticker]) =
  discard settings.saveSetting(Setting.Stickers_Recent, %(stickers.mapIt($it.hash)))

proc getInstalledStickerPacks*(): Table[int, StickerPack] =
  let setting = settings.getSetting[string](Setting.Stickers_PacksInstalled, "{}").parseJson
  result = initTable[int, StickerPack]()
  for i in setting.keys:
    let packId = parseInt(i)
    result[packId] = Json.decode($(setting[i]), StickerPack)
    result[packId].stickers.apply(proc(sticker: var Sticker) =
      sticker.packId = packId)

proc getPackIdForSticker*(packs: Table[int, StickerPack], hash: string): int =
  for packId, pack in packs.pairs:
    if pack.stickers.any(proc(sticker: Sticker): bool = return sticker.hash == hash):
      return packId
  return 0

proc getRecentStickers*(): seq[Sticker] =
  # TODO: this should be a custom `readValue` implementation of nim-json-serialization
  let settings = settings.getSetting[seq[string]](Setting.Stickers_Recent, @[])
  let installedStickers = getInstalledStickerPacks()
  result = newSeq[Sticker]()
  for hash in settings:
    # pack id is not returned from status-go settings, populate here
    let packId = getPackIdForSticker(installedStickers, $hash)
    # .insert instead of .add to effectively reverse the order stickers because
    # stickers are re-reversed when added to the view due to the nature of
    # inserting recent stickers at the front of the list
    result.insert(Sticker(hash: $hash, packId: packId), 0)

proc getAvailableStickerPacks*(chainId: int, running: var Atomic[bool]): Table[int, StickerPack] =
  var availableStickerPacks = initTable[int, StickerPack]()
  try:
    let numPacks = getPackCount(chainId)
    for i in 0..<numPacks:
      if not running.load():
        trace "Sticker pack task interrupted, exiting sticker pack loading"
        break
      try:
        let stickerPack = getPackData(chainId, i.u256, running)
        availableStickerPacks[stickerPack.id] = stickerPack
      except:
        continue
    result = availableStickerPacks
  except RpcException:
    error "Error in getAvailableStickerPacks", message = getCurrentExceptionMsg()
    result = initTable[int, StickerPack]()
