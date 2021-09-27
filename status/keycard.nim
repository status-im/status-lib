import keycard_go

import ./types/[bookmark]

type
    KeycardModel* = ref object

proc newKeycardModel*(): KeycardModel =
  result = KeycardModel()

# proc storeBookmark*(self: BrowserModel, url: string, name: string): Bookmark =
#   result = status_browser.storeBookmark(url, name)

# proc updateBookmark*(self: BrowserModel, ogUrl: string, url: string, name: string) =
#   status_browser.updateBookmark(ogUrl, url, name)

# proc getBookmarks*(self: BrowserModel): string =
#   result = status_browser.getBookmarks()

# proc deleteBookmark*(self: BrowserModel, url: string) =
#   status_browser.deleteBookmark(url)
