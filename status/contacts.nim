import json, chronicles
import ./statusgo_backend/contacts as status_contacts
import ./statusgo_backend/accounts as status_accounts
import ./statusgo_backend/chat as status_chat
import ./types/profile
import ../eventemitter

const DELETE_CONTACT* = "__deleteThisContact__"

type
  ContactModel* = ref object
    events*: EventEmitter

type
  ContactUpdateArgs* = ref object of Args
    contacts*: seq[Profile]

  ContactIdArgs* = ref object of Args
    id*: string

proc newContactModel*(events: EventEmitter): ContactModel =
    result = ContactModel()
    result.events = events

proc saveContact(self: ContactModel, contact: Profile) = 
  var 
    thumbnail = ""
    largeImage = ""
  if contact.identityImage != nil:
    thumbnail = contact.identityImage.thumbnail
    largeImage = contact.identityImage.large    
  
  status_contacts.saveContact(contact.id, contact.ensVerified, contact.ensName, contact.alias, contact.identicon, thumbnail, largeImage, contact.systemTags, contact.localNickname)

proc getContactByID*(self: ContactModel, id: string): Profile =
  return status_contacts.getContactByID(id)
  
proc blockContact*(self: ContactModel, id: string) =
  var contact = self.getContactByID(id)
  contact.systemTags.add(contactBlocked)
  self.saveContact(contact)
  self.events.emit("contactBlocked", ContactIdArgs(id: id))

proc unblockContact*(self: ContactModel, id: string) =
  var contact = self.getContactByID(id)
  contact.systemTags.delete(contact.systemTags.find(contactBlocked))
  self.saveContact(contact)
  self.events.emit("contactUnblocked", ContactIdArgs(id: id))

proc getContacts*(self: ContactModel, useCache: bool = true): seq[Profile] =
  let (contacts, usedCache) = status_contacts.getContacts(useCache)
  if not usedCache:
    self.events.emit("contactUpdate", ContactUpdateArgs(contacts: contacts))

  return contacts

proc getOrCreateContact*(self: ContactModel, id: string): Profile =
  result = self.getContactByID(id)
  if result == nil:
    let alias = status_accounts.generateAlias(id)
    result = Profile(
      id: id,
      username: alias,
      localNickname: "",
      identicon: status_accounts.generateIdenticon(id),
      alias: alias,
      ensName: "",
      ensVerified: false,
      appearance: 0,
      systemTags: @[]
    )

proc setNickName*(self: ContactModel, id: string, localNickname: string, accountKeyUID: string) =
  var contact = self.getOrCreateContact(id)
  let nickname =
    if (localNickname == ""):
      contact.localNickname
    elif (localNickname == DELETE_CONTACT):
      ""
    else:
      localNickname

  contact.localNickname = nickname
  self.saveContact(contact)
  self.events.emit("contactAdded", Args())
  sendContactUpdate(contact.id, accountKeyUID)

proc addContact*(self: ContactModel, id: string, accountKeyUID: string) =
  var contact = self.getOrCreateContact(id)
  
  let updating = contact.systemTags.contains(contactAdded)

  if not updating:
    contact.systemTags.add(contactAdded)
    discard status_chat.createProfileChat(contact.id)
  else:
    let index = contact.systemTags.find(contactBlocked)
    if (index > -1):
      contact.systemTags.delete(index)

  self.saveContact(contact)
  self.events.emit("contactAdded", Args())
  sendContactUpdate(contact.id, accountKeyUID)

  if updating:
    let profile = Profile(
      id: contact.id,
      username: contact.alias,
      identicon: contact.identicon,
      alias: contact.alias,
      ensName: contact.ensName,
      ensVerified: contact.ensVerified,
      appearance: 0,
      systemTags: contact.systemTags,
      localNickname: contact.localNickname
    )
    self.events.emit("contactUpdate", ContactUpdateArgs(contacts: @[profile]))

proc removeContact*(self: ContactModel, id: string) =
  let contact = self.getContactByID(id)
  var idx = contact.systemTags.find(contactAdded)
  if idx >= 0:
    contact.systemTags.delete(idx)

  idx = contact.systemTags.find(contactRequest)
  if idx >= 0:
    contact.systemTags.delete(idx)

  self.saveContact(contact)
  self.events.emit("contactRemoved", Args())

proc isAdded*(self: ContactModel, id: string): bool =
  var contact = self.getContactByID(id)
  if contact.isNil: return false
  contact.systemTags.contains(contactAdded)

proc contactRequestReceived*(self: ContactModel, id: string): bool =
  var contact = self.getContactByID(id)
  if contact.isNil: return false
  contact.systemTags.contains(contactRequest)

proc rejectContactRequest*(self: ContactModel, id: string) =
  let contact = self.getContactByID(id)
  contact.systemTags.delete(contact.systemTags.find(contactRequest))

  self.saveContact(contact)
  self.events.emit("contactRemoved", Args())
