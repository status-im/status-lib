import keycard_go
import json
import types/keycard

include utils/json_utils

type
    KeycardModel* = ref object

proc newKeycardModel*(): KeycardModel =
  result = KeycardModel()

proc start*(self: KeycardModel): string =
  keycard_go.start()

proc stop*(self: KeycardModel): string =
  keycard_go.stop()

proc select*(self: KeycardModel): string =
  let response = keycard_go.select()
  let parsedResponse = parseJson(response)
  let info = KeycardApplicationInfo(
    installed: parsedResponse["applicationInfo"]["installed"].getBool(),
    initialized: parsedResponse["applicationInfo"]["initialized"].getBool(),
    instanceUID: parsedResponse["applicationInfo"]["instanceUID"].getStr(),
    secureChannelPublicKey: parsedResponse["applicationInfo"]["secureChannelPublicKey"].getStr(),
    version: parsedResponse["applicationInfo"]["version"].getInt(),
    availableSlots: parsedResponse["applicationInfo"]["availableSlots"].getInt(),
    keyUID: parsedResponse["applicationInfo"]["keyUID"].getStr(),
    capabilities: parsedResponse["applicationInfo"]["capabilities"].getInt()
  )

