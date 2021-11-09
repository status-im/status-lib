{.used.}

import json, strutils, sequtils, sugar, chronicles, tables
import json_serialization
import ../utils
import ../wallet/account
import ../statusgo_backend/accounts/constants as constants
import ../statusgo_backend/accounts as status_accounts
import ../statusgo_backend/settings as status_settings
import ../statusgo_backend/tokens as status_tokens
import ../eth/contracts as status_contracts
import web3/conversions
from ../utils import parseAddress, wei2Eth
import setting, network
import chronicles

include message_command_parameters
include message_reaction
include message_text_item

type ContentType* {.pure.} = enum
  FetchMoreMessagesButton = -2
  ChatIdentifier = -1,
  Unknown = 0,
  Message = 1,
  Sticker = 2,
  Status = 3,
  Emoji = 4,
  Transaction = 5,
  Group = 6,
  Image = 7,
  Audio = 8
  Community = 9
  Gap = 10
  Edit = 11

type Message* = object
  alias*: string
  userName*: string
  localName*: string
  chatId*: string
  clock*: int
  gapFrom*: int
  gapTo*: int
  commandParameters*: CommandParameters
  contentType*: ContentType
  ensName*: string
  fromAuthor*: string
  id*: string
  identicon*: string
  lineCount*: int
  localChatId*: string
  messageType*: string    # ???
  parsedText*: seq[TextItem]
  # quotedMessage:       # ???
  replace*: string
  responseTo*: string
  rtl*: bool              # ???
  seen*: bool             # ???
  sticker*: string
  stickerPackId*: int
  text*: string
  timestamp*: string
  editedAt*: string
  whisperTimestamp*: string
  isCurrentUser*: bool
  stickerHash*: string
  outgoingStatus*: string
  linkUrls*: string
  image*: string
  audio*: string
  communityId*: string
  audioDurationMs*: int
  hasMention*: bool
  isPinned*: bool
  pinnedBy*: string
  deleted*: bool
  hide*: bool

proc `$`*(self: Message): string =
  result = fmt"Message(id:{self.id}, chatId:{self.chatId}, clock:{self.clock}, from:{self.fromAuthor}, contentType:{self.contentType})"

proc currentUserWalletContainsAddress(address: string): bool =
  if (address.len == 0):
    return false

  let accounts = status_accounts.getWalletAccounts()
  for acc in accounts:
    if (acc.address == address):
      return true

  return false


var identiconIndex = initTable[string, string]()
var aliasIndex = initTable[string, string]()


proc toMessage*(jsonMsg: JsonNode, logMessage: bool = false): Message =
  let publicChatKey = status_settings.getSetting[string](Setting.PublicKey, "0x0")

  var contentType: ContentType
  try:
    contentType = ContentType(jsonMsg{"contentType"}.getInt)
  except:
    warn "Unknown content type received", type = jsonMsg{"contentType"}.getInt
    contentType = ContentType.Message

  let publicKey = jsonMsg{"from"}.getStr

  # TODO: THIS IIS A TEMPORARY SOLUTION. 
  # IDENTICONS ARE GOING TO BE HANDLED VIA AN HTTP SERVER
  # AND ALIAS ARE GOING TO BE REMOVED
  var identicon = ""
  if identiconIndex.hasKey(publicKey):
    identicon = identiconIndex[publicKey]
  else:
    identicon = generateIdenticon(publicKey)

  var alias = ""
  if aliasIndex.hasKey(publicKey):
    alias = aliasIndex[publicKey]
  else:
    alias = generateAlias(publicKey)

  if logMessage:
    debug "message received: ", messageId=jsonMsg{"id"}.getStr

  var message = Message(
      alias: alias,
      userName: "",
      localName: "",
      chatId: jsonMsg{"localChatId"}.getStr,
      clock: jsonMsg{"clock"}.getInt,
      contentType: contentType,
      ensName: jsonMsg{"ensName"}.getStr,
      fromAuthor: publicKey,
      id: jsonMsg{"id"}.getStr,
      identicon: identicon,
      lineCount: jsonMsg{"lineCount"}.getInt,
      localChatId: jsonMsg{"localChatId"}.getStr,
      messageType: jsonMsg{"messageType"}.getStr,
      replace: jsonMsg{"replace"}.getStr,
      editedAt: $jsonMsg{"editedAt"}.getInt,
      responseTo: jsonMsg{"responseTo"}.getStr,
      rtl: jsonMsg{"rtl"}.getBool,
      seen: jsonMsg{"seen"}.getBool,
      text: jsonMsg{"text"}.getStr,
      timestamp: $jsonMsg{"timestamp"}.getInt,
      whisperTimestamp: $jsonMsg{"whisperTimestamp"}.getInt,
      outgoingStatus: $jsonMsg{"outgoingStatus"}.getStr,
      isCurrentUser: publicChatKey == jsonMsg{"from"}.getStr,
      stickerHash: "",
      stickerPackId: -1,
      parsedText: @[],
      linkUrls: "",
      image: $jsonMsg{"image"}.getStr,
      audio: $jsonMsg{"audio"}.getStr,
      communityId: $jsonMsg{"communityId"}.getStr,
      audioDurationMs: jsonMsg{"audioDurationMs"}.getInt,
      deleted: jsonMsg{"deleted"}.getBool,
      hasMention: false,
      hide: false
    )

  if contentType == ContentType.Gap:
    message.gapFrom = jsonMsg["gapParameters"]["from"].getInt
    message.gapTo = jsonMsg["gapParameters"]["to"].getInt

  if jsonMsg.contains("parsedText") and jsonMsg{"parsedText"}.kind != JNull: 
    for text in jsonMsg{"parsedText"}:
      message.parsedText.add(text.toTextItem)

  message.linkUrls = concat(message.parsedText.map(t => t.children.filter(c => c.textType == "link")))
    .filter(t => t.destination.startsWith("http") or t.destination.startsWith("statusim://"))
    .map(t => t.destination)
    .join(" ")

  if message.contentType == ContentType.Sticker:
    message.stickerHash = jsonMsg["sticker"]["hash"].getStr
    message.stickerPackId = jsonMsg["sticker"]["pack"].getInt

  if message.contentType == ContentType.Transaction:
    let
      allContracts = allErc20Contracts().concat(getCustomTokens())
      ethereum = newErc20Contract("Ethereum", Mainnet, parseAddress(constants.ZERO_ADDRESS), "ETH", 18, true)
      tokenAddress = jsonMsg["commandParameters"]["contract"].getStr
      tokenContract = if tokenAddress == "": ethereum else: allContracts.findByAddress(parseAddress(tokenAddress)) 
      tokenContractStr = if tokenContract == nil: "{}" else: $(Json.encode(tokenContract))
    var weiStr = if tokenContract == nil: "0" else: wei2Eth(jsonMsg["commandParameters"]["value"].getStr, tokenContract.decimals)
    weiStr.trimZeros()

    # TODO find a way to use json_seralization for this. When I try, I get an error
    message.commandParameters = CommandParameters(
      id: jsonMsg["commandParameters"]["id"].getStr,
      fromAddress: jsonMsg["commandParameters"]["from"].getStr,
      address: jsonMsg["commandParameters"]["address"].getStr,
      contract: tokenContractStr,
      value: weiStr,
      transactionHash: jsonMsg["commandParameters"]["transactionHash"].getStr,
      commandState: jsonMsg["commandParameters"]["commandState"].getInt,
      signature: jsonMsg["commandParameters"]["signature"].getStr
    )

    # This is kind of a workaround in case we're processing a transaction message. The reason for 
    # that is a message where a recipient accepted to share his address with sender. In that message
    # a recipient's public key is set as a "from" property of a "Message" object and we cannot 
    # determine which of two users has initiated transaction actually. 
    # 
    # To overcome this we're checking if the "from" address from the "commandParameters" object of 
    # the "Message" is contained as an address in the wallet of logged in user. If yes, means that
    # currently logged in user has initiated a transaction (he is a sender), otherwise currently 
    # logged in user is a recipient.
    if message.commandParameters.fromAddress != "":
      message.isCurrentUser = currentUserWalletContainsAddress(message.commandParameters.fromAddress)

  message.hasMention = concat(message.parsedText.map(
    t => t.children.filter(
      c => c.textType == "mention" and c.literal == publicChatKey))).len > 0

  result = message
