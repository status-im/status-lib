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

  return toProfileModel(parseJSON($response)["result"])


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

  contacts = map(response["result"].getElems(), proc(x: JsonNode): Profile = x.toProfileModel())
  for contact in contacts:
    contactsIndex[contact.id] = contact

  return  (contacts, false)

proc getContactsIndex*(): (Table[string, Profile], bool)=
  let cacheIsDirty = (not contactsInited) or dirty.load

  if not cacheIsDirty:
    return (contactsIndex, true)

  discard getContacts()
  return (contactsIndex, false)

proc saveContact*(id: string, ensVerified: bool, ensName: string, alias: string, 
  identicon: string, thumbnail: string, largeImage: string, systemTags: seq[string], 
  localNickname: string) =
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
      "systemTags": systemTags,
      "localNickname": localNickname
    }]
  discard callPrivateRPC("saveContact".prefix, payload)
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
