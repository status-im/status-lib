import json, json_serialization, chronicles, nimcrypto
import ./core, ./utils
import ./response_type

import status_go

export response_type

logScope:
  topics = "rpc-accounts"

const NUMBER_OF_ADDRESSES_TO_GENERATE = 5
const MNEMONIC_PHRASE_LENGTH = 12

const GENERATED* = "generated"
const SEED* = "seed"
const KEY* = "key"
const WATCH* = "watch"

proc getAccounts*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  return core.callPrivateRPC("accounts_getAccounts")

proc deleteAccount*(address: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  return core.callPrivateRPC("accounts_deleteAccount", %* [address])

proc generateAddresses*(paths: seq[string]): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* {
    "n": NUMBER_OF_ADDRESSES_TO_GENERATE,
    "mnemonicPhraseLength": MNEMONIC_PHRASE_LENGTH,
    "bip39Passphrase": "",
    "paths": paths
  }

  try:
    let response = status_go.multiAccountGenerateAndDeriveAddresses($payload)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "generateAddresses", exception=e.msg
    raise newException(RpcException, e.msg)

proc generateAlias*(publicKey: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  try:
    let response = status_go.generateAlias(publicKey)
    result.result = %* response

  except RpcException as e:
    error "error doing rpc request", methodName = "generateAlias", exception=e.msg
    raise newException(RpcException, e.msg)

proc generateIdenticon*(publicKey: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  try:
    let response = status_go.identicon(publicKey)
    result.result = %* response

  except RpcException as e:
    error "error doing rpc request", methodName = "generateIdenticon", exception=e.msg
    raise newException(RpcException, e.msg)

proc multiAccountImportMnemonic*(mnemonic: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* {
    "mnemonicPhrase": mnemonic,
    "Bip39Passphrase": ""
  }
  
  try:
    let response = status_go.multiAccountImportMnemonic($payload)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "multiAccountImportMnemonic", exception=e.msg
    raise newException(RpcException, e.msg)

proc deriveAccounts*(accountId: string, paths: seq[string]): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* {
    "accountID": accountId,
    "paths": paths
  }
  
  try:
    let response = status_go.multiAccountDeriveAddresses($payload)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "deriveAccounts", exception=e.msg
    raise newException(RpcException, e.msg)

proc openedAccounts*(path: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  try:
    let response = status_go.openAccounts(path)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "openedAccounts", exception=e.msg
    raise newException(RpcException, e.msg)

proc storeDerivedAccounts*(id, hashedPassword: string, paths: seq[string]):
  RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* {
    "accountID": id,
    "paths": paths,
    "password": hashedPassword
  }

  try:
    let response = status_go.multiAccountStoreDerivedAccounts($payload)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "storeDerivedAccounts", exception=e.msg
    raise newException(RpcException, e.msg)

proc storeAccounts*(id, hashedPassword: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* {
    "accountID": id,
    "password": hashedPassword
  }

  try:
    let response = status_go.multiAccountStoreAccount($payload)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "storeAccounts", exception=e.msg
    raise newException(RpcException, e.msg)

proc hashPassword*(password: string): string =
  result = "0x" & $keccak_256.digest(password)

proc saveAccount*(
  address: string,
  name: string,
  password: string,
  color: string,
  accountType: string,
  isADerivedAccount = true,
  walletIndex: int = 0,
  id: string = "",
  publicKey: string = "",
) {.raises: [Exception].} =
  var derivationPath = "m/44'/60'/0'/0/0"
  let hashedPassword = hashPassword(password)

  if (isADerivedAccount):
    let derivationPath = (if accountType == GENERATED: "m/" else: "m/44'/60'/0'/0/") & $walletIndex
    discard storeDerivedAccounts(id, hashedPassword, @[derivationPath])
  elif accountType == KEY:
    discard storeAccounts(id, hashedPassword)

  discard callPrivateRPC("accounts_saveAccounts", %* [
    [{
      "color": color,
      "name": name,
      "address": address,
      "public-key": publicKey,
      "type": accountType,
      "path": derivationPath
    }]
  ])

proc addPeer*(peer: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  try:
    let response = status_go.addPeer(peer)
    result.result = %* response

  except RpcException as e:
    error "error doing rpc request", methodName = "addPeer", exception=e.msg
    raise newException(RpcException, e.msg)

proc saveAccountAndLogin*(hashedPassword: string, account, subaccounts, settings,
  config: JsonNode): RpcResponse[JsonNode] {.raises: [Exception].} =
  try:
    let response = status_go.saveAccountAndLogin($account, hashedPassword, 
    $settings, $config, $subaccounts)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "saveAccountAndLogin", exception=e.msg
    raise newException(RpcException, e.msg)

proc login*(name, keyUid, hashedPassword, identicon, thumbnail, large: string): 
  RpcResponse[JsonNode] 
  {.raises: [Exception].} =
  try:
    var payload = %* {
      "name": name,
      "key-uid": keyUid,
      "identityImage": newJNull(),
      "identicon": identicon
    }

    if(thumbnail.len>0 and large.len > 0):
      payload["identityImage"] = %* {"thumbnail": thumbnail, "large": large}

    let response = status_go.login($payload, hashedPassword)
    result.result = Json.decode(response, JsonNode)

  except RpcException as e:
    error "error doing rpc request", methodName = "login", exception=e.msg
    raise newException(RpcException, e.msg)
