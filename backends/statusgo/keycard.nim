import json
import keycard_go

import ../../status/types/[keycard]
import ../types
import ./core

method keycardStart*(self: StatusGoBackend) =
  let response = keycard_go.start()
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardStartException(error: parsedResponse{"error"}.getStr())

method keycardStop*(self: StatusGoBackend) =
  let response = keycard_go.stop()
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardStopException(error: parsedResponse{"error"}.getStr())

method keycardSelect*(self: StatusGoBackend): KeycardApplicationInfo =
  let response = keycard_go.select()
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardSelectException(error: parsedResponse{"error"}.getStr())

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

