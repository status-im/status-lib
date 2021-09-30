import json

import base
import signal_type

type KeycardStartedSignal* = ref object of Signal
  started*: string

proc fromEvent*(T: type KeycardStartedSignal, event: JsonNode): KeycardStartedSignal =
  result = KeycardSignal()
  result.started = event["event"]
