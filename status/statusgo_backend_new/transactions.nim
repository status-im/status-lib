import json

import ./core

proc checkRecentHistory*(addresses: seq[string]) {.raises: [Exception].} =
  let payload = %* [addresses]
  discard callPrivateRPC("wallet_checkRecentHistory", payload)