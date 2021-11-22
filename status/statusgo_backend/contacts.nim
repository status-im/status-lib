import tables, json, strmisc, atomics, sequtils, json_serialization, chronicles
import ./core, ./settings, ./accounts, ../utils, ../types/[profile, setting]

var
  contacts {.threadvar.}: seq[Profile]
  contactsIndex {.threadvar.}: Table[string, Profile]
  contactsInited {.threadvar.}: bool
  dirty: Atomic[bool]

proc getContactByID*(id: string): Profile =
  let response = callPrivateRPC("getContactByID".prefix, %* [id])
  dirty.store(true)
  let responseResult = parseJSON($response)["result"]
  if responseResult == nil or responseResult.kind == JNull:
    return nil

  return toProfile(parseJSON($response)["result"])


proc getContacts*(useCache: bool = true): (seq[Profile], bool) =
  let cacheIsDirty = (not useCache) or (not contactsInited) or dirty.load
  if not cacheIsDirty:
    return (contacts, true)
  
  let payload = %* []
  let response = callPrivateRPC("contacts".prefix, payload).parseJson
  dirty.store(false)
  contactsIndex = initTable[string, Profile]()
  contactsInited = true

  if response["result"].kind == JNull:
    contacts = @[]
    return (contacts, false)

  contacts = map(response["result"].getElems(), proc(x: JsonNode): Profile = x.toProfile())
  for contact in contacts:
    contactsIndex[contact.id] = contact

  return  (contacts, false)

proc getContactsIndex*(): (Table[string, Profile], bool)=
  let cacheIsDirty = (not contactsInited) or dirty.load

  if not cacheIsDirty:
    return (contactsIndex, true)

  discard getContacts()
  return (contactsIndex, false)

proc blockContact*(id: string) =
  discard callPrivateRPC("blockContact".prefix, %* [id])
  dirty.store(true)

proc unblockContact*(id: string) =
  discard callPrivateRPC("unblockContact".prefix, %* [id])
  dirty.store(true)

proc removeContact*(id: string) =
  discard callPrivateRPC("removeContact".prefix, %* [id])
  dirty.store(true)

proc rejectContactRequest*(id: string) =
  let payload = %*[{
    "id": id
  }]
  discard callPrivateRPC("rejectContactRequest".prefix, payload)
  dirty.store(true)

proc setContactLocalNickname*(id: string, name: string) =
  let payload = %* [{
    "id": id,
    "nickname": name
  }]
  discard callPrivateRPC("setContactLocalNickname".prefix, payload)
  dirty.store(true)

proc saveContact*(id: string, ensVerified: bool, ensName: string, alias: string, 
  identicon: string, thumbnail: string, largeImage: string, added: bool, blocked: bool, 
  hasAddedUs: bool, localNickname: string) =
  # TODO: Most of these method arguments aren't used anymore
  # as status-go's RPC API became smarter. Should remove those.
  let payload = %* [{
      "id": id,
      "ensName": ensName
    }]

  discard callPrivateRPC("addContact".prefix, payload)
  dirty.store(true)

proc sendContactUpdate*(publicKey: string, accountKeyUID: string) =
  let preferredUsername = getSetting[string](Setting.PreferredUsername, "")
  let usernames = getSetting[seq[string]](Setting.Usernames, @[])
  var ensName = ""
  if len(preferredUsername) > 0:
    ensName = preferredUsername
  elif len(usernames) >= 1:
    ensName = usernames[0]

  let identityImage = getIdentityImage(accountKeyUID)
  discard callPrivateRPC("sendContactUpdate".prefix, %* [publicKey, ensName, identityImage.thumbnail])
  dirty.store(true)
