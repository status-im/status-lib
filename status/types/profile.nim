{.used.}

import json, strformat
import identity_image

export identity_image

type Profile* = ref object
  id*, alias*, identicon*, name*, localNickname*: string
  ensVerified*: bool
  messagesFromContactsOnly*: bool
  sendUserStatus*: bool
  currentUserStatus*: int
  identityImage*: IdentityImage
  appearance*: int
  systemTags*: seq[string]

proc `$`*(self: Profile): string =
  return fmt"Profile(id:{self.id}, alias:{self.alias})"

proc toProfileModel*(profile: JsonNode): Profile =
  var systemTags: seq[string] = @[]
  if profile["systemTags"].kind != JNull:
    systemTags = profile["systemTags"].to(seq[string])

  result = Profile(
    id: profile["id"].str,
    identicon: profile["identicon"].str,
    identityImage: IdentityImage(),
    alias: profile["alias"].str,
    name: profile{"name"}.getStr,
    ensVerified: profile["ensVerified"].getBool,
    localNickname: profile{"localNickname"}.getStr,
    appearance: 0,
    systemTags: systemTags
  )

  if profile.hasKey("images") and profile["images"].kind != JNull:
    if profile["images"].hasKey("thumbnail"):
      result.identityImage.thumbnail = profile["images"]["thumbnail"]["uri"].str
    if profile["images"].hasKey("large"):
      result.identityImage.large = profile["images"]["large"]["uri"].str