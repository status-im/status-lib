import json
import keycard_go

import ../../types/[keycard]
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

method keycardPair*(self: StatusGoBackend, pairingPassword: string): KeycardPairingInfo =
  let inputJSON = %* {
      "pairingPassword": pairingPassword
    }
  let response = keycard_go.pair($inputJSON)
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardPairException(error: parsedResponse{"error"}.getStr())

  result = KeycardPairingInfo(
    key: parsedResponse["pairingInfo"]["key"].getStr(),
    index: parsedResponse["pairingInfo"]["index"].getInt(),
  )

method keycardOpenSecureChannel*(self: StatusGoBackend, index: int, key: string) =
  let inputJSON = %* {
      "key": key,
      "index": index
    }
  let response = keycard_go.openSecureChannel($inputJSON)
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardOpenSecureChannelException(error: parsedResponse{"error"}.getStr())

method keycardVerifyPin*(self: StatusGoBackend, pin: string) =
  let inputJSON = %* {
      "pin": pin
    }
  let response = keycard_go.verifyPin($inputJSON)
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardVerifyPINException(error: parsedResponse{"error"}.getStr(), remainingAttempts: parsedResponse{"remainingAttempts"}.getInt())

method keycardExportKey*(self: StatusGoBackend, derive: bool, makeCurrent: bool, onlyPublic: bool, path: string): KeycardExportedKey =
  let inputJSON = %* {
      "derive": derive,
      "makeCurrent": makeCurrent,
      "onlyPublic": onlyPublic,
      "path": path
    }
  let response = keycard_go.exportKey($inputJSON)
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardExportKeyException(error: parsedResponse{"error"}.getStr())

  result = KeycardExportedKey(
    privKey: parsedResponse["privateKey"].getStr(),
    pubKey: parsedResponse["publicKey"].getStr()
  )

method keycardGetStatusApplication*(self: StatusGoBackend): KeycardStatus =
  let response = keycard_go.getStatusApplication()
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardGetStatusException(error: parsedResponse{"error"}.getStr())
  result = KeycardStatus(
    pinRetryCount: parsedResponse["status"]["pinRetryCount"].getInt(),
    pukRetryCount: parsedResponse["status"]["pukRetryCount"].getInt(),
    keyInitialized: parsedResponse["status"]["keyInitialized"].getBool()
  )

method keycardUnpair*(self: StatusGoBackend, index: int) =
  let inputJSON = %* {
      "index": index,
    }
  let response = keycard_go.unpair($inputJSON)
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardUnpairException(error: parsedResponse{"error"}.getStr())

method keycardGenerateKey*(self: StatusGoBackend): string =
  let response = keycard_go.generateKey()
  let parsedResponse = parseJson(response)
  if not parsedResponse{"ok"}.getBool():
    raise KeycardGenerateKeyException(error: parsedResponse{"error"}.getStr())
  result = parsedResponse["keyUID"].getStr()
