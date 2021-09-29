import
  json, json_serialization, chronicles, web3/ethtypes

import
  ./core,
  ./conversions,
  ../types/[rpc_response, transaction]

proc estimateGas*(tx: TransactionData): RpcResponse =
  let response = core.callPrivateRPC("eth_estimateGas", %*[%tx])
  result = Json.decode(response, RpcResponse)
  if not result.error.isNil:
    raise newException(RpcException, "Error getting gas estimate: " & result.error.message)

  trace "Gas estimated succesfully", estimate=result.result

proc estimateGas*(tx: var TransactionData, success: var bool): string =
  success = true
  try:
    let response = estimateGas(tx)
    result = response.result
  except RpcException as e:
    success = false
    result = e.msg

proc sendTransaction*(tx: TransactionData, password: string): RpcResponse =
  let responseStr = core.sendTransaction($(%tx), password)
  result = Json.decode(responseStr, RpcResponse)
  if not result.error.isNil:
    raise newException(RpcException, "Error sending transaction: " & result.error.message)

  trace "Transaction sent succesfully", hash=result.result

proc sendTransaction*(tx: var TransactionData, password: string, success: var bool): string =
  success = true
  try:
    let response = sendTransaction(tx, password)
    result = response.result
  except RpcException as e:
    success = false
    result = e.msg

proc call*(tx: TransactionData): RpcResponse =
  let responseStr = core.callPrivateRPC("eth_call", %*[%tx, "latest"])
  result = Json.decode(responseStr, RpcResponse)
  if not result.error.isNil:
    raise newException(RpcException, "Error calling method: " & result.error.message)

proc call*(payload = %* []): RpcResponse =
  let responseStr = core.callPrivateRPC("eth_call", payload)
  result = Json.decode(responseStr, RpcResponse)
  if not result.error.isNil:
    raise newException(RpcException, "Error calling method: " & result.error.message)