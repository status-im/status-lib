import statusgo_backend/browser as status_browser
import ../eventemitter
import ./types/[bookmark]

type
    BrowserModel* = ref object
        events*: EventEmitter

proc newBrowserModel*(events: EventEmitter): BrowserModel =
  result = BrowserModel()
  result.events = events

proc storeBookmark*(self: BrowserModel, bookmark: Bookmark): Bookmark =
  return status_browser.storeBookmark(bookmark)

proc updateBookmark*(self: BrowserModel, originalUrl: string, bookmark: Bookmark) =
  status_browser.updateBookmark(originalUrl, bookmark)

proc getBookmarks*(self: BrowserModel): seq[Bookmark] =
  result = status_browser.getBookmarks()

proc deleteBookmark*(self: BrowserModel, url: string) =
  status_browser.deleteBookmark(url)
