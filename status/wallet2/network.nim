from json import JsonNode, `%*`
from strformat import fmt
from json_serialization import serializedFieldName

type Network* = ref object
  chainID* {.serializedFieldName("chain_id").}: int
  nativeCurrencyDecimals* {.serializedFieldName("native_currency_decimals").}: int
  layer* {.serializedFieldName("layer").}: int
  chainName* {.serializedFieldName("chain_name").}: string
  rpcURL* {.serializedFieldName("rpc_url").}: string
  blockExplorerURL* {.serializedFieldName("block_explorer_url").}: string
  iconURL* {.serializedFieldName("icon_url").}: string
  nativeCurrencyName* {.serializedFieldName("native_currency_name").}: string
  nativeCurrencySymbol* {.serializedFieldName("native_currency_symbol").}: string
  isTest* {.serializedFieldName("is_test").}: bool
  enabled* {.serializedFieldName("enabled").}: bool

proc `$`*(self: Network): string =
  return fmt"Network(chainID:{self.chainID}, name:{self.chainName}, rpcURL:{self.rpcURL}, isTest:{self.isTest}, enabled:{self.enabled})"

proc toPayload*(self: Network): JsonNode =
  return %* [{
    "chain_id": self.chainID, "native_currency_decimals": self.nativeCurrencyDecimals, "layer": self.layer,
    "chain_name": self.chainName, "rpc_url": self.rpcURL, "block_explorer_url": self.blockExplorerURL,
    "icon_url": self.iconURL, "native_currency_name": self.nativeCurrencyName,
    "native_currency_symbol": self.nativeCurrencySymbol, "is_test": self.isTest, "enabled": self.enabled
  }]