import tables, sequtils, json, chronicles

import ../types
import ../../types/[bookmark]

var bookmarks_storage_mock = initTable[string, Bookmark]()

method storeBookmark*(self: MockBackend, bookmark: Bookmark): Bookmark =
  result = bookmark
  bookmarks_storage_mock[bookmark.url] = bookmark

method updateBookmark*(self: MockBackend, originalUrl: string, bookmark: Bookmark) =
  bookmarks_storage_mock.del(originalUrl)
  bookmarks_storage_mock[bookmark.url] = bookmark

method getBookmarks*(self: MockBackend): seq[Bookmark] =
  var bookmarks: seq[Bookmark] = @[]
  for b in bookmarks_storage_mock.values:
    bookmarks.add(b)
  result = bookmarks

method deleteBookmark*(self: MockBackend, url: string) =
  bookmarks_storage_mock.del(url)
