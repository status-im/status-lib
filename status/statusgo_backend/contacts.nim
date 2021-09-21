import tables, json, strmisc, atomics, sugar, sequtils, json_serialization, chronicles
import ./core, ./settings, ./accounts, ../utils, ../types/[profile, setting]

var
  contacts {.threadvar.}: seq[Profile]
  contactsIndex {.threadvar.}: Table[string, Profile]
  contactsInited {.threadvar.}: bool
  dirty: Atomic[bool]

proc getContactByID*(id: string): string =
  result = callPrivateRPC("getContactByID".prefix, %* [id])
  dirty.store(true)

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
  else:
    discard getContacts()
    return (contactsIndex, false)

proc saveContact*(id: string, ensVerified: bool, ensName: string, alias: string, 
  identicon: string, thumbnail: string, largeImage: string, systemTags: seq[string], 
  localNickname: string): string =
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
  # TODO: StatusGoError handling
  result = callPrivateRPC("saveContact".prefix, payload)
  dirty.store(true)

proc sendContactUpdate*(publicKey: string, accountKeyUID: string) : string =
  let preferredUsername = getSetting[string](Setting.PreferredUsername, "")
  let usernames = getSetting[seq[string]](Setting.Usernames, @[])
  var ensName = ""
  if len(preferredUsername) > 0:
    ensName = preferredUsername
  elif len(usernames) >= 1:
    ensName = usernames[0]

  let identityImage = getIdentityImage(accountKeyUID)
  result = callPrivateRPC("sendContactUpdate".prefix, %* [publicKey, ensName, identityImage.thumbnail])
  dirty.store(true)
