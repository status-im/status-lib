import keycard_go
import ../types/keycard
import ../backends/backend

include utils/json_utils

type KeycardModel* = ref object
  backend*: Backend

proc newKeycardModel*(backend: Backend): KeycardModel =
  result = KeycardModel()
  result.backend = backend

proc start*(self: KeycardModel) =
  try:
    self.backend.keycardStart()
  except:
    raise

proc stop*(self: KeycardModel) =
  try:
    self.backend.keycardStop()
  except:
    raise

proc select*(self: KeycardModel): KeycardApplicationInfo =
  try:
    result = self.backend.keycardSelect()
  except:
    raise

proc pair*(self: KeycardModel, pairingPassword: string): KeycardPairingInfo =
  try:
    result = self.backend.keycardPair(pairingPassword)
  except:
    raise

proc openSecureChannel*(self: KeycardModel, index: int, key: string) =
  try:
    self.backend.keycardOpenSecureChannel(index, key)
  except:
    raise

proc verifyPin*(self: KeycardModel, pin: string) =
  try:
    self.backend.keycardVerifyPin(pin)
  except:
    raise

proc exportKey*(self: KeycardModel, derive: bool, makeCurrent: bool, onlyPublic: bool, path: string): KeycardExportedKey =
  try:
    result = self.backend.keycardExportKey(derive, makeCurrent, onlyPublic, path)
  except:
    raise

proc getStatusApplication*(self: KeycardModel): KeycardStatus =
  try:
    result = self.backend.keycardGetStatusApplication()
  except:
    raise

proc unpair*(self: KeycardModel, index: int) =
  try:
    self.backend.keycardUnpair(index)
  except:
    raise

proc generateKey*(self: KeycardModel): string =
  try:
    result = self.backend.keycardGenerateKey()
  except:
    raise
