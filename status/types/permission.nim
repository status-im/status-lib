import sets
import strutils
import chronicles

logScope:
  topics = "permission-type"

type
  Permission* {.pure.} = enum
    Web3 = "web3",
    ContactCode = "contact-code"
    Unknown = "unknown"

type Dapp* = object
  name*: string
  permissions*: HashSet[Permission]

proc toPermission*(value: string): Permission =
  result = Permission.Unknown
  try:
    result = parseEnum[Permission](value)
  except:
    warn "Unknown permission requested", value
