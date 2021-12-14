import statusgo_backend/settings as status_settings
import statusgo_backend/tokens as statusgo_backend_tokens
import ./statusgo_backend/network
import eth/tokens as status_tokens
import eth/contracts
import ./types/network_type
import ../eventemitter

type
    TokensModel* = ref object
        events*: EventEmitter

proc newTokensModel*(events: EventEmitter): TokensModel =
  result = TokensModel()
  result.events = events

proc getSNTAddress*(): string =
  let network = status_settings.getCurrentNetwork().toNetwork()
  result = status_tokens.getSNTAddress(network)

proc getCustomTokens*(self: TokensModel, useCached: bool = true): seq[Erc20Contract] =
  result = statusgo_backend_tokens.getCustomTokens(useCached)

proc removeCustomToken*(self: TokensModel, address: string) =
  statusgo_backend_tokens.removeCustomToken(address)

proc getSNTBalance*(account: string): string =
  let network = status_settings.getCurrentNetwork().toNetwork()
  result = status_tokens.getSNTBalance(network, account)

proc tokenDecimals*(contract: Contract): int =
  result = status_tokens.tokenDecimals(contract)

proc tokenName*(contract: Contract): string =
  result = status_tokens.tokenName(contract)

proc tokensymbol*(contract: Contract): string =
  result = status_tokens.tokensymbol(contract)

proc getTokenBalance*(tokenAddress: string, account: string): string = 
  let network = status_settings.getCurrentNetwork().toNetwork()
  result = status_tokens.getTokenBalance(network, tokenAddress, account)

proc getToken*(self: TokensModel, tokenAddress: string): Erc20Contract =
  let network = status_settings.getCurrentNetwork().toNetwork()
  result = status_tokens.getToken(network, tokenAddress)

export newErc20Contract
export allErc20ContractsByChainId
export Erc20Contract
export findByAddress
