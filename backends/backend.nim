from ./types import Backend, StatusGoBackend, MockBackend
export Backend, StatusGoBackend, MockBackend

from base/bookmarks as bookmarks_methods import storeBookmark, updateBookmark, getBookmarks, deleteBookmark
export storeBookmark, updateBookmark, getBookmarks, deleteBookmark

from base/keycard as keycard_methods import keycardStart, keycardStop, keycardSelect, keycardPair,
  keycardOpenSecureChannel, keycardVerifyPin, keycardExportKey, keycardGetStatusApplication
export keycardStart, keycardStop, keycardSelect, keycardPair,
  keycardOpenSecureChannel, keycardVerifyPin, keycardExportKey, keycardGetStatusApplication

import statusgo/bookmarks as statusgo_bookmarks
import mock/bookmarks as mock_bookmarks
import statusgo/keycard as statusgo_keycard
import mock/keycard as mock_keycard

proc newBackend*(name: string): Backend =
  if name == "statusgo":
    result = StatusGoBackend()
  elif name == "mock":
    result = MockBackend()
  else:
    raise newException(ValueError, "unknown backend")
