import json, sequtils

import ./settings
import ../types/[setting, gif_item]

proc getRecentGifs*(): seq[GifItem] =
  let node = settings.getSetting[JsonNode](Setting.Gifs_Recent, %*{})
  return map(node{"items"}.getElems(), settingToGifItem)

proc getFavoriteGifs*(): seq[GifItem] =
  let node = settings.getSetting[JsonNode](Setting.Gifs_Favorite, %*{})
  return map(node{"items"}.getElems(), settingToGifItem)

proc setFavoriteGifs*(gifItems: seq[GifItem]) =
  let node = %*{"items": map(gifItems, toJsonNode)}
  discard settings.saveSetting(Setting.Gifs_Favorite, node)

proc setRecentGifs*(gifItems: seq[GifItem]) =
  let node = %*{"items": map(gifItems, toJsonNode)}
  discard settings.saveSetting(Setting.Gifs_Recent, node)