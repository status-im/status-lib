import json, chronicles
import core, utils
import response_type

export response_type

logScope:
  topics = "status-lib-mailserver"

proc saveMailserver*(id: string, name: string, enode: string, fleet: string): 
  RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [{
      "id": id,
      "name": name,
      "address": enode,
      "fleet": fleet
    }]
  result = core.callPrivateRPC("mailservers_addMailserver", payload)

proc getMailservers*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = core.callPrivateRPC("mailservers_getMailservers")

proc setMailserver*(peer: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [peer]
  result = core.callPrivateRPC("setMailserver".prefix, payload)
  info "setMailserver", topics="mailserver-interaction", rpc_method="wakuext_setMailserver", peer, result

proc update*(peer: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [[peer]]
  result = core.callPrivateRPC("updateMailservers".prefix, payload)
  info "update", topics="mailserver-interaction", rpc_method="wakuext_updateMailservers", peer, result

proc requestAllHistoricMessages*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* []
  result = core.callPrivateRPC("requestAllHistoricMessages".prefix, payload)
  info "requestAllHistoricMessages", topics="mailserver-interaction", rpc_method="mailservers_requestAllHistoricMessages"

proc requestStoreMessages*(topics: seq[string], timeout: int, symKeyID: string, peer: string, numberOfMessages: int, 
  fromTimestamp: int64, toTimestamp: int64, force: bool): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload =  %* [
    {
        "topics": topics,
        "mailServerPeer": peer,
        "timeout": timeout,
        "limit": numberOfMessages,
        "cursor": nil,
        "from": fromTimestamp,
        "to": toTimestamp,
        "force": force
    }
  ]
  result = core.callPrivateRPC("requestMessages".prefix, payload)
  info "setMailserver", topics="mailserver-interaction", rpc_method="requestMessages", peer, result

proc syncChatFromSyncedFrom*(chatId: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %*[chatId]
  result = core.callPrivateRPC("syncChatFromSyncedFrom".prefix, payload)
  info "syncChatFromSyncedFrom", topics="mailserver-interaction", rpc_method="wakuext_syncChatFromSyncedFrom", chatId, result

proc fillGaps*(chatId: string, messageIds: seq[string]): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %*[chatId, messageIds]
  result = core.callPrivateRPC("fillGaps".prefix, payload)
  info "fillGaps", topics="mailserver-interaction", rpc_method="wakuext_fillGaps", chatId, messageIds, result

proc ping*(addresses: seq[string], timeoutMs: int, isWakuV2: bool = false): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [{ 
    "addresses": addresses, 
    "timeoutMs": timeoutMs 
    }]
  var rpcMethod = if isWakuV2: "mailservers_multiAddressPing" else: "mailservers_ping"
  result = core.callPrivateRPC(rpcMethod, payload)
  info "ping", topics="mailserver-interaction", rpc_method="mailservers_ping", addresses, timeoutMs, result

proc delete*(peer: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [peer]
  result = core.callPrivateRPC("mailservers_deleteMailserver", payload)
  info "delete", topics="mailserver-interaction", rpc_method="mailservers_deleteMailserver", peer, result