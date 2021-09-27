import keycard_go

type
    KeycardModel* = ref object

proc newKeycardModel*(): KeycardModel =
  result = KeycardModel()

proc start*(self: KeycardModel): string =
  keycard_go.start()

proc stop*(self: KeycardModel): string =
  keycard_go.stop()

proc select*(self: KeycardModel): string =
  keycard_go.select()

