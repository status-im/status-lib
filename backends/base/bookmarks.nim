import ../../types/[bookmark]
import ../backend_type

method storeBookmark*(self: Backend, bookmark: Bookmark): Bookmark =
    raise newException(ValueError, "No implementation available")

method updateBookmark*(self: Backend, originalUrl: string, bookmark: Bookmark) =
    raise newException(ValueError, "No implementation available")

method getBookmarks*(self: Backend): seq[Bookmark] =
    raise newException(ValueError, "No implementation available")

method deleteBookmark*(self: Backend, url: string) =
    raise newException(ValueError, "No implementation available")
