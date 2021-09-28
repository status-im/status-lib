import json, strformat

type
  GifItem* = object
    id*: string
    title*: string
    url*: string
    tinyUrl*: string
    height*: int

proc tenorToGifItem*(jsonMsg: JsonNode): GifItem =
  return GifItem(
    id: jsonMsg{"id"}.getStr,
    title: jsonMsg{"title"}.getStr,
    url: jsonMsg{"media"}[0]["gif"]["url"].getStr,
    tinyUrl: jsonMsg{"media"}[0]["tinygif"]["url"].getStr,
    height: jsonMsg{"media"}[0]["gif"]["dims"][1].getInt
  )

proc settingToGifItem*(jsonMsg: JsonNode): GifItem =
  return GifItem(
    id: jsonMsg{"id"}.getStr,
    title: jsonMsg{"title"}.getStr,
    url: jsonMsg{"url"}.getStr,
    tinyUrl: jsonMsg{"tinyUrl"}.getStr,
    height: jsonMsg{"height"}.getInt
  )

proc toJsonNode*(self: GifItem): JsonNode =
  result = %* {
    "id": self.id,
    "title": self.title,
    "url": self.url,
    "tinyUrl": self.tinyUrl,
    "height": self.height
  }

proc `$`*(self: GifItem): string =
  return fmt"GifItem(id:{self.id}, title:{self.title}, url:{self.url}, tinyUrl:{self.tinyUrl}, height:{self.height})"
