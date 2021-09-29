# import statusgo_backend/browser as status_browser
import ../eventemitter

import ../types/[bookmark]

import ../backends/backend

type
  BrowserModel* = ref object
    events*: EventEmitter
    backend*: Backend

proc newBrowserModel*(events: EventEmitter, backend: Backend): BrowserModel =
  result = BrowserModel()
  result.events = events
  result.backend = backend

proc storeBookmark*(self: BrowserModel, bookmark: Bookmark): Bookmark =
  return self.backend.storeBookmark(bookmark)

proc updateBookmark*(self: BrowserModel, originalUrl: string, bookmark: Bookmark) =
  self.backend.updateBookmark(originalUrl, bookmark)

proc getBookmarks*(self: BrowserModel): seq[Bookmark] =
  result = self.backend.getBookmarks()

proc deleteBookmark*(self: BrowserModel, url: string) =
  self.backend.deleteBookmark(url)
