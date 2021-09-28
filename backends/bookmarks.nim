import backend_type, backend_wrapper
import base/bookmarks
import ../types/[bookmark]

proc storeBookmark*(self: BackendWrapper, bookmark: Bookmark): Bookmark =
    self.backend.storeBookmark(bookmark)

proc updateBookmark*(self: BackendWrapper, originalUrl: string, bookmark: Bookmark) =
    self.backend.updateBookmark(originalUrl, bookmark)

proc getBookmarks*(self: BackendWrapper): seq[Bookmark] =
    self.backend.getBookmarks()

proc deleteBookmark*(self: BackendWrapper, url: string) =
    self.backend.deleteBookmark(url)
