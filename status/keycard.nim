import keycard_go

type
    KeycardModel* = ref object

proc newKeycardModel*(): KeycardModel =
  result = KeycardModel()

# proc storeBookmark*(self: KeycardModel) =
#   result = keycard_go.Select()

