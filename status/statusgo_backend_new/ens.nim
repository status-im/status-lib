import json, web3/[conversions, ethtypes]
import ./core, ./response_type
import ../types/transaction
import ./conversions as conv
import ./utils
export response_type

proc resolver*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]

  return core.callPrivateRPC("ens_resolver", payload)

proc ownerOf*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]

  return core.callPrivateRPC("ens_ownerOf", payload)

proc contentHash*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]

  return core.callPrivateRPC("ens_contentHash", payload)

proc publicKeyOf*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]

  return core.callPrivateRPC("ens_publicKeyOf", payload)

proc addressOf*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]

  return core.callPrivateRPC("ens_addressOf", payload)

proc expireAt*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]

  return core.callPrivateRPC("ens_expireAt", payload)

proc price*(chainId: int): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId]
  return core.callPrivateRPC("ens_price", payload)

proc resourceURL*(chainId: int, username: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, username]
  return core.callPrivateRPC("ens_resourceURL", payload)

proc register*(
  chainId: int, txData: TransactionData, password: string, username: string, pubkey: string
): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, txData, hashPassword(password), username, pubkey]
  return core.callPrivateRPC("ens_register", payload)

proc registerEstimate*(
  chainId: int, txData: TransactionData, username: string, pubkey: string
): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, txData, username, pubkey]
  return core.callPrivateRPC("ens_registerEstimate", payload)

proc release*(
  chainId: int, txData: TransactionData, password: string, username: string
): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, txData, hashPassword(password), username]
  return core.callPrivateRPC("ens_release", payload)

proc releaseEstimate*(
  chainId: int, txData: TransactionData, username: string
): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, txData, username]
  return core.callPrivateRPC("ens_releaseEstimate", payload)

proc setPubKey*(
  chainId: int, txData: TransactionData, password: string, username: string, pubkey: string
): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, txData, hashPassword(password), username, pubkey]
  return core.callPrivateRPC("ens_setPubKey", payload)

proc setPubKeyEstimate*(
  chainId: int, txData: TransactionData, username: string, pubkey: string
): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [chainId, txData, username, pubkey]
  return core.callPrivateRPC("ens_setPubKeyEstimate", payload)