import ../types/[profile, account]

export profile

const contactAdded* = ":contact/added"
const contactBlocked* = ":contact/blocked"
const contactRequest* = ":contact/request-received"

proc isContact*(self: Profile): bool =
  result = self.systemTags.contains(contactAdded)

proc isBlocked*(self: Profile): bool =
  result = self.systemTags.contains(contactBlocked)

proc requestReceived*(self: Profile): bool =
  result = self.systemTags.contains(contactRequest)

proc toProfileModel*(account: Account): Profile =
  result = Profile(
    id: "",
    identicon: account.identicon,
    alias: account.name,
    name: "",
    ensVerified: false,
    appearance: 0,
    systemTags: @[]
  )
