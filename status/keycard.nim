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
