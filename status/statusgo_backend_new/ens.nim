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
import ./eth

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

const registry* = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"
const resolver_signature = "0x0178b8bf"
proc resolver*(usernameHash: string): string =
  let payload = %* [{
    "to": registry,
    "from": "0x0000000000000000000000000000000000000000",
    "data": fmt"{resolver_signature}{userNameHash}"
  }, "latest"]

  var resolverAddr = eth.call(payload).result.getStr()
  resolverAddr.removePrefix("0x000000000000000000000000")
  result = "0x" & resolverAddr

const contenthash_signature = "0xbc1c58d1" # contenthash(bytes32)
proc contenthash*(ensAddr: string): string =
  var ensHash = namehash(ensAddr)
  ensHash.removePrefix("0x")
  let ensResolver = resolver(ensHash)
  let payload = %* [{
    "to": ensResolver,
    "from": "0x0000000000000000000000000000000000000000",
    "data": fmt"{contenthash_signature}{ensHash}"
  }, "latest"]

  let bytesResponse =  eth.call(payload).result.getStr()
  if bytesResponse == "0x":
    return ""

  let size = fromHex(Stuint[256], bytesResponse[66..129]).truncate(int)
  result = bytesResponse[130..129+size*2]
