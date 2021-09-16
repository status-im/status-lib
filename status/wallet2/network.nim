from json import JsonNode, `%*`, parseJson
from strformat import fmt
import json_serialization

type Network* = ref object
  chainID* {.serializedFieldName("chainId").}: int
  nativeCurrencyDecimals* {.serializedFieldName("nativeCurrencyDecimals").}: int
  layer* {.serializedFieldName("layer").}: int
  chainName* {.serializedFieldName("chainName").}: string
  rpcURL* {.serializedFieldName("rpcUrl").}: string
  blockExplorerURL* {.serializedFieldName("blockExplorerUrl").}: string
  iconURL* {.serializedFieldName("iconUrl").}: string
  nativeCurrencyName* {.serializedFieldName("nativeCurrencyName").}: string
  nativeCurrencySymbol* {.serializedFieldName("nativeCurrencySymbol").}: string
  isTest* {.serializedFieldName("isTest").}: bool
  enabled* {.serializedFieldName("enabled").}: bool

proc `$`*(self: Network): string =
  return fmt"Network(chainID:{self.chainID}, name:{self.chainName}, rpcURL:{self.rpcURL}, isTest:{self.isTest}, enabled:{self.enabled})"

proc toPayload*(self: Network): JsonNode =
  return %* [Json.encode(self).parseJson]