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

proc blockContact*(id: string) =
  discard callPrivateRPC("blockContact".prefix, %* [id])

proc unblockContact*(id: string) =
  discard callPrivateRPC("unblockContact".prefix, %* [id])

proc removeContact*(id: string) =
  discard callPrivateRPC("removeContact".prefix, %* [id])

proc rejectContactRequest*(id: string) =
  let payload = %*[{
    "id": id
  }]
  discard callPrivateRPC("rejectContactRequest".prefix, payload)

proc setContactLocalNickname*(id: string, name: string) =
  let payload = %* [{
    "id": id,
    "nickname": name
  }]
  discard callPrivateRPC("setContactLocalNickname".prefix, payload)

proc saveContact*(id: string, ensVerified: bool, ensName: string, alias: string, 
  identicon: string, thumbnail: string, largeImage: string, added: bool, 
  blocked: bool, hasAddedUs: bool, localNickname: string) 
  {.raises: [Exception].} =
  # TODO: Most of these method arguments aren't used anymore
  # as status-go's RPC API became smarter. Should remove those.
  let payload = %* [{
      "id": id,
      "ensName": ensName
    }]

  discard callPrivateRPC("addContact".prefix, payload)

proc sendContactUpdate*(publicKey, ensName, thumbnail: string)
  {.raises: [Exception].} =
  let payload = %* [publicKey, ensName, thumbnail]
  discard callPrivateRPC("sendContactUpdate".prefix, payload)
  
