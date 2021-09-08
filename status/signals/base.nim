import json
import json_serialization
import signal_type
import ../status
import ../types/rpc_response

import ../../eventemitter

export signal_type

type Signal* = ref object of Args
  signalType* {.serializedFieldName("type").}: SignalType
  signalTypeStr*: string

type NodeSignal* = ref object of Signal
  event*: StatusGoError
