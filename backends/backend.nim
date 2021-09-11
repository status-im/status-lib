import backend_type

import backend_wrapper
export backend_wrapper

from statusgo/types as statusgo_types import StatusGoBackend
from mock/types  as mock_types import MockBackend
export StatusGoBackend
export MockBackend

import base/bookmarks

import statusgo/statusgo_instance
export newStatusGoBackendInstance

import mock/mock_instance
export newMockBackendInstance

import statusgo/bookmark as statusgo_bookmark
import mock/bookmark as mock_bookmark

from bookmarks as bookmarks_methods import storeBookmark, updateBookmark, getBookmarks, deleteBookmark
export storeBookmark, updateBookmark, getBookmarks, deleteBookmark

method loadBackend*(self: BackendWrapper, name: string) =
    if name == "statusgo":
        self.backend = newStatusGoBackendInstance()
    if name == "mock":
        self.backend = newMockBackendInstance()
    else:
        raise newException(ValueError, "unknown backend")
