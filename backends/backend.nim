from ./types import Backend, StatusGoBackend, MockBackend
export Backend, StatusGoBackend, MockBackend

from base/bookmarks as bookmarks_methods import storeBookmark, updateBookmark, getBookmarks, deleteBookmark
export storeBookmark, updateBookmark, getBookmarks, deleteBookmark

import statusgo/bookmarks as statusgo_bookmarks
import mock/bookmarks as mock_bookmarks

proc newBackend*(name: string): Backend = 
  if name == "statusgo":
    result = StatusGoBackend()
  elif name == "mock":
    result = MockBackend()
  else:
    raise newException(ValueError, "unknown backend")