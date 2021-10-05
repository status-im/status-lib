{.used.}

import strutils
import web3/ethtypes, options, stint
include pending_transaction_type

type
  PendingTransaction* = ref object
    hash*: string
    success*: bool
    txType*: PendingTransactionType

  Transaction* = ref object
    id*: string
    typeValue*: string
    address*: string
    blockNumber*: string
    blockHash*: string
    contract*: string
    timestamp*: string
    gasPrice*: string
    gasLimit*: string
    gasUsed*: string
    nonce*: string
    txStatus*: string
    value*: string
    fromAddress*: string
    to*: string

type
  TransactionData* = object
    source*: Address             # the address the transaction is send from.
    to*: Option[Address]         # (optional when creating new contract) the address the transaction is directed to.
    gas*: Option[Quantity]            # (optional, default: 90000) integer of the gas provided for the transaction execution. It will return unused gas.
    gasPrice*: Option[int]       # (optional, default: To-Be-Determined) integer of the gasPrice used for each paid gas.
    maxPriorityFeePerGas*: Option[Uint256]
    maxFeePerGas*: Option[Uint256]
    value*: Option[Uint256]          # (optional) integer of the value sent with this transaction.
    data*: string                # the compiled code of a contract OR the hash of the invoked method signature and encoded parameters. For details see Ethereum Contract ABI.
    nonce*: Option[Nonce]        # (optional) integer of a nonce. This allows to overwrite your own pending transactions that use the same nonce
    txType*: string

proc cmpTransactions*(x, y: Transaction): int =
  # Sort proc to compare transactions from a single account.
  # Compares first by block number, then by nonce
  result = cmp(x.blockNumber.parseHexInt, y.blockNumber.parseHexInt)
  if result == 0:
    result = cmp(x.nonce, y.nonce)
