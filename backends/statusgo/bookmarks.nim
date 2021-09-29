import json, chronicles

import ../../types/[bookmark]
import ../types
import ./core

method storeBookmark*(self: StatusGoBackend, bookmark: Bookmark): Bookmark =
  let payload = %* [{"url": bookmark.url, "name": bookmark.name}]
  try:
    let resp = callPrivateRPC("browsers_storeBookmark", payload).parseJson["result"]
    bookmark.imageUrl = resp["imageUrl"].getStr
    return bookmark
  except Exception as e:
    error "Error updating bookmark", msg = e.msg
    discard

method updateBookmark*(self: StatusGoBackend, originalUrl: string, bookmark: Bookmark) =
  let payload = %* [originalUrl, {"url": bookmark.url, "name": bookmark.name}]
  try:
    discard callPrivateRPC("browsers_updateBookmark", payload)
  except Exception as e:
    error "Error updating bookmark", msg = e.msg
    discard

method getBookmarks*(self: StatusGoBackend): seq[Bookmark] =
  let payload = %* []
  try:
    let responseResult = callPrivateRPC("browsers_getBookmarks", payload).parseJson["result"]
    if responseResult.kind != JNull:
      for bookmark in responseResult:
        result.add(Bookmark(url: bookmark{"url"}.getStr, name: bookmark{"name"}.getStr, imageUrl: bookmark{"imageUrl"}.getStr))
  except:
    discard

method deleteBookmark*(self: StatusGoBackend, url: string) =
  let payload = %* [url]
  discard callPrivateRPC("browsers_deleteBookmark", payload)
