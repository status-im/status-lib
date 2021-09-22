{.used.}

import strutils, strformat
import web3/ethtypes, options, stint
import ../../eventemitter
include pending_transaction_type

type
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
    maxFeePerGas*: string
    maxPriorityFeePerGas*: string
    input*: string
    txHash*: string
    networkId*: int
  
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

type 
  WalletTransactionsArg* = ref object of Args
    address*: string
    transactions*: seq[Transaction]

proc cmpTransactions*(x, y: Transaction): int =
  # Sort proc to compare transactions from a single account.
  # Compares first by block number, then by nonce
  result = cmp(x.blockNumber.parseHexInt, y.blockNumber.parseHexInt)
  if result == 0:
    result = cmp(x.nonce, y.nonce)

proc `$`*(self: Transaction): string =
  result = "Transaction("
  result &= fmt"id:{self.id}, "
  result &= fmt"typeValue:{self.typeValue}, "
  result &= fmt"address:{self.address}, "
  result &= fmt"blockNumber:{self.blockNumber}, "
  result &= fmt"blockHash:{self.blockHash}, "
  result &= fmt"contract:{self.contract}, "  
  result &= fmt"timestamp:{self.timestamp}, "
  result &= fmt"gasPrice:{self.gasPrice}, "
  result &= fmt"gasLimit:{self.gasLimit}, "
  result &= fmt"gasUsed:{self.gasUsed}, "
  result &= fmt"nonce:{self.nonce}, "
  result &= fmt"txStatus:{self.txStatus}, "
  result &= fmt"value:{self.value}, "
  result &= fmt"fromAddress:{self.fromAddress}, "
  result &= fmt"maxFeePerGas:{self.maxFeePerGas}, "
  result &= fmt"maxPriorityFeePerGas:{self.maxPriorityFeePerGas}, "
  result &= fmt"input:{self.input}, "
  result &= fmt"txHash:{self.txHash}, "
  result &= fmt"networkId:{self.networkId}"
  result &= ")"