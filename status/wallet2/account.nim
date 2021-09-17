import Tables, options, json, strformat, strutils

from ../../eventemitter import Args
import ../types/[transaction]

type CollectibleList* = ref object
    collectibleType*, collectiblesJSON*, error*: string
    loading*: int

type Collectible* = ref object
    name*, image*, id*, collectibleType*, description*, externalUrl*: string

type OpenseaCollectionTrait* = ref object
    min*, max*: float

type OpenseaCollection* = ref object
    name*, slug*, imageUrl*: string
    ownedAssetCount*: int
    trait*: Table[string, OpenseaCollectionTrait]

type OpenseaTrait* = ref object
    traitType*, value*, displayType*, maxValue*: string

type OpenseaAsset* = ref object
    id*: int
    name*, description*, permalink*, imageThumbnailUrl*, imageUrl*, address*, backgroundColor*: string
    properties*, rankings*, statistics*: seq[OpenseaTrait]

type CurrencyArgs* = ref object of Args
    currency*: string

type Asset* = ref object
    name*, symbol*, value*, fiatBalanceDisplay*, fiatBalance*,  accountAddress*, address*: string

type WalletAccount* = ref object
    name*, address*, iconColor*, path*, walletType*, publicKey*: string
    balance*: Option[string]
    realFiatBalance*: Option[float]
    assetList*: seq[Asset]
    wallet*, chat*: bool
    collectiblesLists*: seq[CollectibleList]
    transactions*: tuple[hasMore: bool, data: seq[Transaction]]

type TraitType* {.pure.} = enum
  Properties = 0,
  Rankings = 1,
  Statistics = 2

proc isNumeric(s: string): bool =
  try:
    discard s.parseFloat()
    result = true
  except ValueError:
    result = false

proc newWalletAccount*(name, address, iconColor, path, walletType, publicKey: string,
  wallet, chat: bool, assets: seq[Asset]): WalletAccount =
  result = new WalletAccount
  result.name = name
  result.address = address
  result.iconColor = iconColor
  result.path = path
  result.walletType = walletType
  result.publicKey = publicKey
  result.wallet = wallet
  result.chat = chat
  result.assetList = assets
  result.balance = none[string]()
  result.realFiatBalance = none[float]()

type AccountArgs* = ref object of Args
    account*: WalletAccount

proc `$`*(self: OpenseaCollection): string =
  return fmt"OpenseaCollection(name:{self.name}, slug:{self.slug}, owned asset count:{self.ownedAssetCount})"

proc `$`*(self: OpenseaAsset): string =
  return fmt"OpenseaAsset(id:{self.id}, name:{self.name}, address:{self.address}, imageUrl: {self.imageUrl}, imageThumbnailUrl: {self.imageThumbnailUrl}, backgroundColor: {self.backgroundColor})"

proc getOpenseaCollectionTraits*(jsonCollection: JsonNode): Table[string, OpenseaCollectionTrait] =
    var traitList: Table[string, OpenseaCollectionTrait] = initTable[string, OpenseaCollectionTrait]()
    if jsonCollection.hasKey("traits"):
        for key, value in jsonCollection{"traits"}:
            traitList[key] = OpenseaCollectionTrait(min: value{"min"}.getFloat, max: value{"max"}.getFloat)
    return traitList

proc toOpenseaCollection*(jsonCollection: JsonNode): OpenseaCollection =
    return OpenseaCollection(
        name: jsonCollection{"name"}.getStr,
        slug: jsonCollection{"slug"}.getStr,
        imageUrl: jsonCollection{"image_url"}.getStr,
        ownedAssetCount: jsonCollection{"owned_asset_count"}.getInt,
        trait: getOpenseaCollectionTraits(jsonCollection)
    )

proc getOpenseaTraits*(jsonAsset: JsonNode, traitType: TraitType): seq[OpenseaTrait] =
    var traitList: seq[OpenseaTrait] = @[]
    case traitType:
        of TraitType.Properties:
            for index in jsonAsset{"traits"}.items:
                if((index{"display_type"}.getStr != "number") and (index{"display_type"}.getStr != "boost_percentage") and (index{"display_type"}.getStr != "boost_number") and not isNumeric(index{"value"}.getStr)):
                    traitList.add(OpenseaTrait(traitType: index{"trait_type"}.getStr, value: index{"value"}.getStr, displayType: index{"display_type"}.getStr, maxValue: index{"max_value"}.getStr))
        of TraitType.Rankings:
            for index in jsonAsset{"traits"}.items:
                if(index{"display_type"}.getStr != "number" and (index{"display_type"}.getStr != "boost_percentage") and (index{"display_type"}.getStr != "boost_number") and isNumeric(index{"value"}.getStr)):
                    traitList.add(OpenseaTrait(traitType: index{"trait_type"}.getStr, value: index{"value"}.getStr, displayType: index{"display_type"}.getStr, maxValue: index{"max_value"}.getStr))
        of TraitType.Statistics:
            for index in jsonAsset{"traits"}.items:
                if(index{"display_type"}.getStr == "number" and (index{"display_type"}.getStr != "boost_percentage") and (index{"display_type"}.getStr != "boost_number") and isNumeric(index{"value"}.getStr)):
                    traitList.add(OpenseaTrait(traitType: index{"trait_type"}.getStr, value: index{"value"}.getStr, displayType: index{"display_type"}.getStr, maxValue: index{"max_value"}.getStr))
    return traitList

proc toOpenseaAsset*(jsonAsset: JsonNode): OpenseaAsset =
    return OpenseaAsset(
        id: jsonAsset{"id"}.getInt,
        name: jsonAsset{"name"}.getStr,
        description: jsonAsset{"description"}.getStr,
        permalink: jsonAsset{"permalink"}.getStr,
        imageThumbnailUrl: jsonAsset{"image_thumbnail_url"}.getStr,
        imageUrl: jsonAsset{"image_url"}.getStr,
        address: jsonAsset{"asset_contract"}{"address"}.getStr,
        backgroundColor: jsonAsset{"background_color"}.getStr,
        properties: getOpenseaTraits(jsonAsset, TraitType.Properties),
        rankings: getOpenseaTraits(jsonAsset, TraitType.Rankings),
        statistics: getOpenseaTraits(jsonAsset, TraitType.Statistics)
    )
