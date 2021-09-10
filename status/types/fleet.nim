{.used.}

import json, typetraits, tables, sequtils

type
  Fleet* {.pure.} = enum
    Prod = "eth.prod",
    Staging = "eth.staging",
    Test = "eth.test",
    WakuV2Prod = "wakuv2.prod"
    WakuV2Test = "wakuv2.test"

  FleetNodes* {.pure.} = enum
    Bootnodes = "boot",
    Mailservers = "mail",
    Rendezvous = "rendezvous",
    Whisper = "whisper",
    Waku = "waku"

  FleetMeta* = object
    hostname*: string
    timestamp*: uint64

  FleetConfig* = object
    fleet*: Table[string, Table[string, Table[string, string]]]
    meta*: FleetMeta


proc toFleetConfig*(jsonString: string): FleetConfig =
  let fleetJson = jsonString.parseJSON
  result.meta.hostname = fleetJson["meta"]["hostname"].getStr
  result.meta.timestamp = fleetJson["meta"]["timestamp"].getBiggestInt.uint64
  result.fleet = initTable[string, Table[string, Table[string, string]]]()

  for fleet in fleetJson["fleets"].keys():
    result.fleet[fleet] = initTable[string, Table[string, string]]()
    for nodes in fleetJson["fleets"][fleet].keys():
      result.fleet[fleet][nodes] = initTable[string, string]()
      for server in fleetJson["fleets"][fleet][nodes].keys():
        result.fleet[fleet][nodes][server] = fleetJson["fleets"][fleet][nodes][server].getStr


proc getNodes*(self: FleetConfig, fleet: Fleet, nodeType: FleetNodes = FleetNodes.Bootnodes): seq[string] =
  if not self.fleet[$fleet].hasKey($nodeType): return
  result = toSeq(self.fleet[$fleet][$nodeType].values)

proc getMailservers*(self: FleetConfig, fleet: Fleet, isWakuV2: bool): Table[string, string] =
  # TODO: If using wakuV2, this assumes that Waku nodes in fleet.status.json are also store nodes. 
  # Maybe it make senses to add a "waku-store" section in case we want to have separate node types?
  # Discuss with @iurimatias, @cammellos and Vac team
  let fleetKey = if isWakuV2: $FleetNodes.Waku else: $FleetNodes.Mailservers
  if not self.fleet[$fleet].hasKey(fleetKey) :  
    result = initTable[string,string]()
    return
  result = self.fleet[$fleet][fleetKey]

