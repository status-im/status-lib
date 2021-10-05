{.used.}

import json, strformat
import identity_image

export identity_image

const contactAdded* = ":contact/added"
const contactBlocked* = ":contact/blocked"
const contactRequest* = ":contact/request-received"

type Profile* = ref object
  id*, alias*, username*, identicon*, address*, ensName*, localNickname*: string
  ensVerified*: bool
  messagesFromContactsOnly*: bool
  sendUserStatus*: bool
  currentUserStatus*: int
  identityImage*: IdentityImage
  appearance*: int
  added*: bool
  blocked*: bool
  hasAddedUs*: bool

proc `$`*(self: Profile): string =
  return fmt"Profile(id:{self.id}, username:{self.username}, added: {self.added}, blocked: {self.blocked}, hasAddedUs: {self.hasAddedUs}, ensName: {self.ensName})"

proc toProfile*(jsonNode: JsonNode): Profile =
  result = Profile(
    id: jsonNode["id"].str,
    username: jsonNode["alias"].str,
    identicon: jsonNode["identicon"].str,
    identityImage: IdentityImage(),
    address: jsonNode["id"].str,
    alias: jsonNode["alias"].str,
    ensName: "",
    ensVerified: jsonNode["ensVerified"].getBool,
    appearance: 0,
    added: jsonNode["added"].getBool,
    blocked: jsonNode["blocked"].getBool,
    hasAddedUs: jsonNode["hasAddedUs"].getBool,
  )
  
  if jsonNode.hasKey("name"):
    result.ensName = jsonNode["name"].str
  
  if jsonNode.hasKey("localNickname"):
    result.localNickname = jsonNode["localNickname"].str

  if jsonNode.hasKey("images") and jsonNode["images"].kind != JNull:
    if jsonNode["images"].hasKey("thumbnail"):
      result.identityImage.thumbnail = jsonNode["images"]["thumbnail"]["uri"].str
    if jsonNode["images"].hasKey("large"):
      result.identityImage.large = jsonNode["images"]["large"]["uri"].str

proc isContact*(self: Profile): bool =
  result = self.added

proc isBlocked*(self: Profile): bool =
  result = self.blocked

proc requestReceived*(self: Profile): bool =
  result = self.hasAddedUs