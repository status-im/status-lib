import json, times, chronicles
import core, ../utils

proc ping*(mailservers: seq[string], timeoutMs: int, isWakuV2: bool = false): string =
  var addresses: seq[string] = @[]
  for mailserver in mailservers:
    addresses.add(mailserver)
  var rpcMethod = if isWakuV2: "mailservers_multiAddressPing" else: "mailservers_ping"
  result = callPrivateRPC(rpcMethod, %* [
    { "addresses": addresses, "timeoutMs": timeoutMs }
  ])
  info "ping", topics="mailserver-interaction", rpc_method="mailservers_ping", addresses, timeoutMs, result

proc update*(peer: string) =
  let response = callPrivateRPC("updateMailservers".prefix, %* [[peer]])
  info "update", topics="mailserver-interaction", rpc_method="wakuext_updateMailservers", peer, response

proc setMailserver*(peer: string): string =
  result = callPrivateRPC("setMailserver".prefix, %* [peer])
  info "setMailserver", topics="mailserver-interaction", rpc_method="wakuext_setMailserver", peer, result

proc delete*(peer: string) =
  let response = callPrivateRPC("mailservers_deleteMailserver", %* [peer])
  info "delete", topics="mailserver-interaction", rpc_method="mailservers_deleteMailserver", peer, response

proc requestAllHistoricMessages*(): string =
  result = callPrivateRPC("requestAllHistoricMessages".prefix, %*[])
  info "requestAllHistoricMessages", topics="mailserver-interaction", rpc_method="mailservers_requestAllHistoricMessages"

proc requestStoreMessages*(topics: seq[string], symKeyID: string, peer: string, numberOfMessages: int, fromTimestamp: int64 = 0, toTimestamp: int64 = 0, force: bool = false) =
  var toValue = times.toUnix(times.getTime())
  var fromValue = toValue - 86400
  if fromTimestamp != 0:
    fromValue = fromTimestamp
  if toTimestamp != 0:
    toValue = toTimestamp

  echo callPrivateRPC("requestMessages".prefix, %* [
    {
        "topics": topics,
        "mailServerPeer": "16Uiu2HAmVVi6Q4j7MAKVibquW8aA27UNrA4Q8Wkz9EetGViu8ZF1",
        "timeout": 30,
        "limit": numberOfMessages,
        "cursor": nil,
        "from": fromValue,
        "to": toValue,
        "force": force
    }
  ])

proc syncChatFromSyncedFrom*(chatId: string): string =
  result = callPrivateRPC("syncChatFromSyncedFrom".prefix, %*[chatId])
  info "syncChatFromSyncedFrom", topics="mailserver-interaction", rpc_method="wakuext_syncChatFromSyncedFrom", chatId, result

proc fillGaps*(chatId: string, messageIds: seq[string]): string =
  result = callPrivateRPC("fillGaps".prefix, %*[chatId, messageIds])
  info "fillGaps", topics="mailserver-interaction", rpc_method="wakuext_fillGaps", chatId, messageIds, result
