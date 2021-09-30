import json
import keycard_go

import ../../status/types/[keycard]
import ../types
import ./core

method keycardStart*(self: StatusGoBackend): string =
  result = keycard_go.start()

method keycardStop*(self: StatusGoBackend): string =
  result = keycard_go.stop()

method keycardSelect*(self: StatusGoBackend): KeycardApplicationInfo =
  let response = keycard_go.select()
  let parsedResponse = parseJson(response)
  return KeycardApplicationInfo(
    installed: parsedResponse["applicationInfo"]["installed"].getBool(),
    initialized: parsedResponse["applicationInfo"]["initialized"].getBool(),
    instanceUID: parsedResponse["applicationInfo"]["instanceUID"].getStr(),
    secureChannelPublicKey: parsedResponse["applicationInfo"]["secureChannelPublicKey"].getStr(),
    version: parsedResponse["applicationInfo"]["version"].getInt(),
    availableSlots: parsedResponse["applicationInfo"]["availableSlots"].getInt(),
    keyUID: parsedResponse["applicationInfo"]["keyUID"].getStr(),
    capabilities: parsedResponse["applicationInfo"]["capabilities"].getInt()
  )

