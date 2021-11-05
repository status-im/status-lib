import json, strmisc
import core, utils
import response_type

export response_type

proc getContacts*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* []
  result = callPrivateRPC("contacts".prefix, payload)

proc getContactById*(id: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [id]
  result = callPrivateRPC("getContactByID".prefix, payload)

proc saveContact*(id: string, ensVerified: bool, ensName: string, alias: string, 
  identicon: string, thumbnail: string, largeImage: string, added: bool, 
  blocked: bool, hasAddedUs: bool, localNickname: string) 
  {.raises: [Exception].} =
  let payload = %* [{
    "id": id,
    "name": ensName,
    "ensVerified": ensVerified,
    "alias": alias,
    "identicon": identicon,
    "images": {
      "thumbnail": {"Payload": thumbnail.partition(",")[2]},
      "large": {"Payload": largeImage.partition(",")[2]}
      },
    "added": added,
    "blocked": blocked,
    "hasAddedUs": hasAddedUs,
    "localNickname": localNickname
  }]

  discard callPrivateRPC("saveContact".prefix, payload)

proc sendContactUpdate*(publicKey, ensName, thumbnail: string)
  {.raises: [Exception].} =
  let payload = %* [publicKey, ensName, thumbnail]
  discard callPrivateRPC("sendContactUpdate".prefix, payload)
  