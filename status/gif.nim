import httpclient
import json
import strformat
import os
import uri
import chronicles

import types/gif_item
from statusgo_backend/gif import getRecentGifs, getFavoriteGifs, setFavoriteGifs, setRecentGifs

logScope:
  topics = "gif"

const MAX_RECENT = 50
# set via `nim c` param `-d:TENOR_API_KEY:[api_key]`; should be set in CI/release builds
const TENOR_API_KEY {.strdefine.} = ""
let TENOR_API_KEY_ENV = $getEnv("TENOR_API_KEY")

let TENOR_API_KEY_RESOLVED =
  if TENOR_API_KEY_ENV != "":
    TENOR_API_KEY_ENV
  else:
    TENOR_API_KEY

const baseUrl = "https://g.tenor.com/v1/"
let defaultParams = fmt("&media_filter=minimal&limit=50&key={TENOR_API_KEY_RESOLVED}")

type
  GifClient* = ref object
    client: HttpClient
    favorites: seq[GifItem]
    recents: seq[GifItem]
    favoritesLoaded: bool
    recentsLoaded: bool

proc newGifClient*(): GifClient =
  result = GifClient()
  result.client = newHttpClient()
  result.favorites = @[]
  result.recents = @[]

proc getContentWithRetry(self: GifClient, path: string, maxRetry: int = 3): string =
  var currentRetry = 0
  while true:
    try:
      let content = self.client.getContent(fmt("{baseUrl}{path}{defaultParams}"))
      return content
    except Exception as e:
      currentRetry += 1
      error "could not query tenor API", msg=e.msg

      if currentRetry >= maxRetry:
        raise

      sleep(100 * currentRetry)

proc tenorQuery(self: GifClient, path: string): seq[GifItem] =
  try:
    let content = self.getContentWithRetry(path)
    let doc = content.parseJson()

    var items: seq[GifItem] = @[]
    for json in doc["results"]:
      items.add(tenorToGifItem(json))

    return items
  except:
    return @[]

proc search*(self: GifClient, query: string): seq[GifItem] =
  return self.tenorQuery(fmt("search?q={encodeUrl(query)}"))

proc getTrendings*(self: GifClient): seq[GifItem] =
  return self.tenorQuery("trending?")

proc getFavorites*(self: GifClient): seq[GifItem] =
  if not self.favoritesLoaded:
    self.favoritesLoaded = true
    self.favorites = getFavoriteGifs()

  return self.favorites

proc getRecents*(self: GifClient): seq[GifItem] =
  if not self.recentsLoaded:
    self.recentsLoaded = true
    self.recents = getRecentGifs()

  return self.recents

proc isFavorite*(self: GifClient, gifItem: GifItem): bool =
  for favorite in self.getFavorites():
    if favorite.id == gifItem.id:
      return true

  return false

proc toggleFavorite*(self: GifClient, gifItem: GifItem) =
  var newFavorites: seq[GifItem] = @[]
  var found = false

  for favoriteGif in self.getFavorites():
    if favoriteGif.id == gifItem.id:
      found = true
      continue

    newFavorites.add(favoriteGif)

  if not found:
    newFavorites.add(gifItem)

  self.favorites = newFavorites
  setFavoriteGifs(newFavorites)

proc addToRecents*(self: GifClient, gifItem: GifItem) =
  let recents = self.getRecents()
  var newRecents: seq[GifItem] = @[gifItem]
  var idx = 0

  while idx < MAX_RECENT - 1:
    if idx >= recents.len:
      break

    if recents[idx].id == gifItem.id:
      idx += 1
      continue

    newRecents.add(recents[idx])
    idx += 1

  self.recents = newRecents
  setRecentGifs(newRecents)