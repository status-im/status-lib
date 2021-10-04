{.used.}

import json_serialization, json

import ../../eventemitter
import ./identity_image
import ./profile

include ./multi_accounts
export identity_image

type
  Account* = ref object of RootObj
    name*: string
    keyUid* {.serializedFieldName("key-uid").}: string
    identityImage*: IdentityImage
    identicon*: string
    isKeycard* {.dontSerialize.}: bool

type
  NodeAccount* = ref object of Account
    timestamp*: int
    keycardPairing* {.serializedFieldName("keycard-pairing").}: string

type
  GeneratedAccount* = ref object
    publicKey*: string
    address*: string
    id*: string
    mnemonic*: string
    derived*: MultiAccounts
    # FIXME: should inherit from Account but multiAccountGenerateAndDeriveAddresses
    # response has a camel-cased properties like "publicKey" and "keyUid", so the
    # serializedFieldName pragma would need to be different
    name*: string
    keyUid*: string
    identicon*: string
    identityImage*: IdentityImage
    isKeycard*: bool

proc isKeycard*(account: NodeAccount): bool =
  result = account.keycardPairing != ""

proc toAccount*(account: GeneratedAccount): Account =
  result = Account(name: account.name, identityImage: account.identityImage, identicon: account.identicon, keyUid: account.keyUid, isKeycard: account.isKeycard)

proc toAccount*(account: NodeAccount): Account =
  result = Account(name: account.name, identityImage: account.identityImage, identicon: account.identicon, keyUid: account.keyUid, isKeycard: isKeycard(account))

type AccountArgs* = ref object of Args
    account*: Account

proc toProfile*(account: Account): Profile =
  result = Profile(
    id: "",
    username: account.name,
    identicon: account.identicon,
    alias: account.name,
    ensName: "",
    ensVerified: false,
    appearance: 0,
    systemTags: @[]
  )
