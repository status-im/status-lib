import sequtils
import strformat
import strutils
import nimcrypto
import json
import json_serialization
import tables
import stew/byteutils
import unicode
import algorithm
import web3/[ethtypes, conversions], stew/byteutils, stint
import chronicles, libp2p/[multihash, multicodec, cid]

import ./statusgo_backend/eth as eth
import ./statusgo_backend/wallet
import ./statusgo_backend/accounts as status_accounts
import ./statusgo_backend/settings as status_settings
import ./statusgo_backend_new/ens as status_ens

import ./types/[transaction, setting, rpc_response, network_type, network, profile]
import ./utils
import ./transactions
import ./eth/contracts

const domain* = ".stateofus.eth"

proc userName*(ensName: string, removeSuffix: bool = false): string =
  if ensName != "" and ensName.endsWith(domain):
    if removeSuffix:
      result = ensName.split(".")[0]
    else:
      result = ensName
  else:
    if ensName.endsWith(".eth") and removeSuffix:
      return ensName.split(".")[0]
    result = ensName

proc addDomain*(username: string): string =
  if username.endsWith(".eth"):
    return username
  else:
    return username & domain

proc hasNickname*(contact: Profile): bool = contact.localNickname != ""

proc userNameOrAlias*(contact: Profile, removeSuffix: bool = false): string =
  if(contact.ensName != "" and contact.ensVerified):
    result = "@" & userName(contact.ensName, removeSuffix)
  elif(contact.localNickname != ""):
    result = contact.localNickname
  else:
    result = contact.alias

proc resolver*(username: string): string =
  let chainId = status_settings.getCurrentNetwork().toChainId()
  let res = status_ens.resolver(chainId, username)
  return res.result.getStr

proc owner*(username: string): string =
  let chainId = status_settings.getCurrentNetwork().toChainId()
  let res = status_ens.ownerOf(chainId, username)
  let address = res.result.getStr
  if address == "0x0000000000000000000000000000000000000000":
    return ""
  
  return address

proc pubkey*(username: string): string =
  try:
    let chainId = status_settings.getCurrentNetwork().toChainId()
    let res = status_ens.publicKeyOf(chainId, addDomain(username))
    var key = res.result.getStr
    key.removePrefix("0x")
    return "0x04" & key
  except:
    return ""

proc address*(username: string): string =
  let chainId = status_settings.getCurrentNetwork().toChainId()
  let res = status_ens.addressOf(chainId, username)
  return res.result.getStr

proc contenthash*(username: string): string =
  let chainId = status_settings.getCurrentNetwork().toChainId()
  let res = status_ens.contentHash(chainId, username)
  return res.result.getStr

proc getPrice*(): Stuint[256] =
  let chainId = status_settings.getCurrentNetwork().toChainId()
  let res = status_ens.price(chainId)
  return fromHex(Stuint[256], res.result.getStr)

proc label*(username:string): string =
  var node:array[32, byte] = keccak_256.digest(username.toLower()).data
  result = "0x" & node.toHex()

proc namehash*(ensName:string): string =
  let name = ensName.toLower()
  var node:array[32, byte]

  node.fill(0)
  var parts = name.split(".")
  for i in countdown(parts.len - 1,0):
    let elem = keccak_256.digest(parts[i]).data
    var concatArrays: array[64, byte]
    concatArrays[0..31] = node
    concatArrays[32..63] = elem
    node = keccak_256.digest(concatArrays).data

  result = "0x" & node.toHex()

proc releaseEstimateGas*(username: string, address: string, success: var bool): int =
  let
    label = fromHex(FixedBytes[32], label(username))
    network = status_settings.getCurrentNetwork().toNetwork()
    ensUsernamesContract = contracts.findContract(network.chainId, "ens-usernames")
    release = Release(label: label)

  var tx = transactions.buildTokenTransaction(parseAddress(address), ensUsernamesContract.address, "", "")
  try:
    let response = ensUsernamesContract.methods["release"].estimateGas(tx, release, success)
    if success:
      result = fromHex[int](response)
  except rpc_response.RpcException as e:
    error "Could not estimate gas for ens release", err=e.msg

proc release*(username: string, address: string, gas, gasPrice,  password: string, success: var bool): string =
  let
    label = fromHex(FixedBytes[32], label(username))
    network = status_settings.getCurrentNetwork().toNetwork()
    ensUsernamesContract = contracts.findContract(network.chainId, "ens-usernames")
    release = Release(label: label)

  var tx = transactions.buildTokenTransaction(parseAddress(address), ensUsernamesContract.address, "", "")
  try:
    result = ensUsernamesContract.methods["release"].send(tx, release, password, success)
    if success:
      trackPendingTransaction(result, address, $ensUsernamesContract.address, PendingTransactionType.ReleaseENS, username)
  except rpc_response.RpcException as e:
    error "Could not estimate gas for ens release", err=e.msg

proc getExpirationTime*(username: string, success: var bool): int =
  let chainId = status_settings.getCurrentNetwork().toChainId()
  let res = status_ens.expireAt(chainId, username)
  return fromHex[int](res.result.getStr)

proc extractCoordinates*(pubkey: string):tuple[x: string, y:string] =
  result = ("0x" & pubkey[4..67], "0x" & pubkey[68..131])

proc registerUsernameEstimateGas*(username: string, address: string, pubKey: string, success: var bool): int =
  let
    label = fromHex(FixedBytes[32], label(username))
    coordinates = extractCoordinates(pubkey)
    x = fromHex(FixedBytes[32], coordinates.x)
    y =  fromHex(FixedBytes[32], coordinates.y)
    network = status_settings.getCurrentNetwork().toNetwork()
    ensUsernamesContract = contracts.findContract(network.chainId, "ens-usernames")
    sntContract = contracts.findErc20Contract(network.chainId, network.sntSymbol())
    price = getPrice()

  let
    register = Register(label: label, account: parseAddress(address), x: x, y: y)
    registerAbiEncoded = ensUsernamesContract.methods["register"].encodeAbi(register)
    approveAndCallObj = ApproveAndCall[132](to: ensUsernamesContract.address, value: price, data: DynamicBytes[132].fromHex(registerAbiEncoded))
    approveAndCallAbiEncoded = sntContract.methods["approveAndCall"].encodeAbi(approveAndCallObj)

  var tx = transactions.buildTokenTransaction(parseAddress(address), sntContract.address, "", "")

  let response = sntContract.methods["approveAndCall"].estimateGas(tx, approveAndCallObj, success)
  if success:
    result = fromHex[int](response)

proc registerUsername*(username, pubKey, address, gas, gasPrice: string, isEIP1559Enabled: bool, maxPriorityFeePerGas: string, maxFeePerGas: string, password: string, success: var bool): string =
  let
    label = fromHex(FixedBytes[32], label(username))
    coordinates = extractCoordinates(pubkey)
    x = fromHex(FixedBytes[32], coordinates.x)
    y =  fromHex(FixedBytes[32], coordinates.y)
    network = status_settings.getCurrentNetwork().toNetwork()
    ensUsernamesContract = contracts.findContract(network.chainId, "ens-usernames")
    sntContract = contracts.findErc20Contract(network.chainId, network.sntSymbol)
    price = getPrice()

  let
    register = Register(label: label, account: parseAddress(address), x: x, y: y)
    registerAbiEncoded = ensUsernamesContract.methods["register"].encodeAbi(register)
    approveAndCallObj = ApproveAndCall[132](to: ensUsernamesContract.address, value: price, data: DynamicBytes[132].fromHex(registerAbiEncoded))

  var tx = transactions.buildTokenTransaction(parseAddress(address), sntContract.address, gas, gasPrice, isEIP1559Enabled, maxPriorityFeePerGas, maxFeePerGas)

  result = sntContract.methods["approveAndCall"].send(tx, approveAndCallObj, password, success)
  if success:
    trackPendingTransaction(result, address, $sntContract.address, PendingTransactionType.RegisterENS, username & domain)

proc setPubKeyEstimateGas*(username: string, address: string, pubKey: string, success: var bool): int =
  var hash = namehash(username)
  hash.removePrefix("0x")

  let
    label = fromHex(FixedBytes[32], "0x" & hash)
    x = fromHex(FixedBytes[32], "0x" & pubkey[4..67])
    y =  fromHex(FixedBytes[32], "0x" & pubkey[68..131])
    network = status_settings.getCurrentNetwork().toNetwork()
    resolverContract = contracts.findContract(network.chainId, "ens-resolver")
    setPubkey = SetPubkey(label: label, x: x, y: y)
    resolverAddress = resolver(hash)

  var tx = transactions.buildTokenTransaction(parseAddress(address), parseAddress(resolverAddress), "", "")

  try:
    let response = resolverContract.methods["setPubkey"].estimateGas(tx, setPubkey, success)
    if success:
      result = fromHex[int](response)
  except rpc_response.RpcException as e:
    raise

proc setPubKey*(username, pubKey, address, gas, gasPrice: string, isEIP1559Enabled: bool, maxPriorityFeePerGas: string, maxFeePerGas: string, password: string, success: var bool): string =
  var hash = namehash(username)
  hash.removePrefix("0x")

  let
    label = fromHex(FixedBytes[32], "0x" & hash)
    x = fromHex(FixedBytes[32], "0x" & pubkey[4..67])
    y =  fromHex(FixedBytes[32], "0x" & pubkey[68..131])
    network = status_settings.getCurrentNetwork().toNetwork()
    resolverContract = contracts.findContract(network.chainId, "ens-resolver")
    setPubkey = SetPubkey(label: label, x: x, y: y)
    resolverAddress = resolver(hash)

  var tx = transactions.buildTokenTransaction(parseAddress(address), parseAddress(resolverAddress), gas, gasPrice, isEIP1559Enabled, maxPriorityFeePerGas, maxFeePerGas)

  try:
    result = resolverContract.methods["setPubkey"].send(tx, setPubkey, password, success)
    if success:
      trackPendingTransaction(result, $address, resolverAddress, PendingTransactionType.SetPubKey, username)
  except rpc_response.RpcException as e:
    raise

proc statusRegistrarAddress*():string =
  let network = status_settings.getCurrentNetwork().toNetwork()
  let contract = contracts.findContract(network.chainId, "ens-usernames")
  if contract != nil:
     return $contract.address
  result = ""

proc validateEnsName*(ens: string, isStatus: bool, usernames: seq[string]): string =
  var username = ens & (if(isStatus): domain else: "")
  result = ""
  if usernames.filter(proc(x: string):bool = x == username).len > 0:
    result = "already-connected"
  else:
    let ownerAddr = owner(username)
    if ownerAddr == "" and isStatus:
      result = "available"
    else:
      let userPubKey = status_settings.getSetting[string](Setting.PublicKey, "0x0")
      let userWallet = status_accounts.getWalletAccounts()[0].address
      let ens_pubkey = pubkey(ens)
      if ownerAddr != "":
        if ens_pubkey == "" and ownerAddr == userWallet:
          result = "owned" # "Continuing will connect this username with your chat key."
        elif ens_pubkey == userPubkey:
          result = "connected"
        elif ownerAddr == userWallet:
          result = "connected-different-key" #  "Continuing will require a transaction to connect the username with your current chat key.",
        else:
          result = "taken"
      else:
        result = "taken"
