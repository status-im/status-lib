from sequtils import concat, map
import sugar, json
from web3/conversions import `$`
import statusgo_backend/network as statusgo_backend_network
import statusgo_backend/tokens as statusgo_backend_tokens
import eth/tokens as status_tokens
import eth/contracts
import types/[network_type, token]
import ../eventemitter

type
  Tokens2Model* = ref object
    events*: EventEmitter

proc newTokens2Model*(events: EventEmitter): Tokens2Model =
  result = Tokens2Model()
  result.events = events

proc fetchErc20Contracts(self: Tokens2Model): seq[Erc20Contract] = 
  for network in statusgo_backend_network.getNetworks():
    if not network.enabled:
      continue

    result = concat(result, status_tokens.getVisibleTokens(network))

proc fetchCustomErc20Contracts(self: Tokens2Model, useCached: bool = true): seq[Erc20Contract] =
  result = statusgo_backend_tokens.getCustomTokens(useCached)

proc loadTokensForAddress*(self: Tokens2Model, accountAddress: string): seq[Token] = 
  let contracts = concat(self.fetchErc20Contracts(), self.fetchCustomErc20Contracts())
  let contractAddresses = contracts.map(contract => $contract.address)
  let chainIds = contracts.map(contract => contract.chainId)
  let tokenBalances = statusgo_backend_tokens.getTokensBalancesForChainIDs(chainIds, @[accountAddress], contractAddresses)

  for contract in contracts:
    let balance = tokenBalances{accountAddress}{$contract.address}.getStr

    result.add(Token(
      name: contract.name,
      symbol: contract.symbol,
      balance: balance,
      fiatBalance: "0", # TODO: fetch balance
      address: $contract.address
    )) 