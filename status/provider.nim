import ens, wallet, permissions, utils
import ../eventemitter
import ./types/[setting, permission]
import utils
import statusgo_backend/accounts
import statusgo_backend/core
import statusgo_backend/settings as status_settings
import json, json_serialization, sets, strutils
import chronicles
import stew/byteutils
from stew/base32 import nil
from stew/base58 import nil

const HTTPS_SCHEME* = "https"
const IPFS_GATEWAY* =  ".infura.status.im"
const SWARM_GATEWAY* = "swarm-gateways.net"

logScope:
  topics = "provider-model"

type ProviderModel* = ref object
  events*: EventEmitter
  permissions*: PermissionsModel
  wallet*: WalletModel

proc newProviderModel*(events: EventEmitter, permissions: PermissionsModel, wallet: WalletModel): ProviderModel =
  result = ProviderModel()
  result.events = events
  result.permissions = permissions
  result.wallet = wallet

proc ensResourceURL*(self: ProviderModel, ens: string, url: string):
  (string, string, string, string, bool) =

  let contentHash = contenthash(ens)
  if contentHash == "": # ENS does not have a content hash
    return (url, url, HTTPS_SCHEME, "", false)

  let decodedHash = contentHash.decodeENSContentHash()

  case decodedHash[0]:
    of ENSType.IPFS:
      let
        base58bytes = base58.decode(base58.BTCBase58, decodedHash[1])
        base32Hash = base32.encode(base32.Base32Lower, base58bytes)

      result = (url, base32Hash & IPFS_GATEWAY, HTTPS_SCHEME, "", true)

    of ENSType.SWARM:
      result = (url, SWARM_GATEWAY, HTTPS_SCHEME,
        "/bzz:/" & decodedHash[1] & "/", true)

    of ENSType.IPNS:
      result = (url, decodedHash[1], HTTPS_SCHEME, "", true)

    else:
      warn "Unknown content for", ens, contentHash
