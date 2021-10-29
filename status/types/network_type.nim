{.used.}

include node_config
include network_details
include upstream_config

import ./network

type
  NetworkType* {.pure.} = enum
    Mainnet = "mainnet_rpc",
    Testnet = "testnet_rpc",
    Rinkeby = "rinkeby_rpc",
    Goerli = "goerli_rpc",
    XDai = "xdai_rpc",
    Poa = "poa_rpc",
    Other = "other"

proc toChainId*(self: NetworkType): int =
  case self:
    of NetworkType.Mainnet: result = Mainnet
    of NetworkType.Testnet: result = Ropsten
    of NetworkType.Rinkeby: result = Rinkeby
    of NetworkType.Goerli: result = Goerli
    of NetworkType.XDai: result = XDai
    of NetworkType.Poa: result = 99
    of NetworkType.Other: result = -1
