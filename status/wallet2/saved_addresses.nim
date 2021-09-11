import
  std/json

import
  chronicles, json_serialization, stew/results

import # modules
  ../types/[address, conversions, rpc_response], ../statusgo_backend/wallet

export address, results

type
  SavedAddressError* = enum
    CreateSavedAddressError     = "error creating saved address"
    DeleteSavedAddressError     = "error deleting saved address"
    ParseAddressError           = "error parsing address"
    ReadSavedAddressesError     = "error reading saved addresses"
    UpdateSavedAddressError     = "error updating saved address"

  SavedAddressResult*[T] = Result[T, SavedAddressError]

proc addSavedAddress*(savedAddress: SavedAddress): SavedAddressResult[void] =
  let
    rpcResponseRaw = wallet.addSavedAddress(
      savedAddress.name, $savedAddress.address)
    rpcResponse = Json.decode(rpcResponseRaw, RpcResponseTyped[JsonNode])
  if not rpcResponse.error.isNil:
    error "error creating saved address", error = rpcResponse.error.message
    return err SavedAddressError.CreateSavedAddressError
  return ok()

proc deleteSavedAddress*(address: Address): SavedAddressResult[void] =
  let
    rpcResponseRaw = wallet.deleteSavedAddress($address)
    rpcResponse = Json.decode(rpcResponseRaw, RpcResponseTyped[JsonNode])
  if not rpcResponse.error.isNil:
    error "error deleting saved address", error = rpcResponse.error.message
    return err SavedAddressError.DeleteSavedAddressError
  return ok()

proc editSavedAddress*(savedAddress: SavedAddress): SavedAddressResult[void] =
  return savedAddress.addSavedAddress

proc getSavedAddresses*(): SavedAddressResult[seq[SavedAddress]] =
  let
    rpcResponseRaw = wallet.getSavedAddresses()
    rpcResponse = Json.decode(rpcResponseRaw, RpcResponseTyped[JsonNode])
  if not rpcResponse.error.isNil:
    error "error getting saved addresses", error = rpcResponse.error.message
    return err SavedAddressError.ReadSavedAddressesError
  if rpcResponse.result.isNil or rpcResponse.result.kind == JNull:
    return ok newSeq[SavedAddress]()
  return ok Json.decode($rpcResponse.result, seq[SavedAddress])