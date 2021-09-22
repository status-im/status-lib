import json, json_serialization

import 
  sugar, sequtils, strutils, atomics

import statusgo_backend/settings as statusgo_backend_settings
import ../eventemitter
import ./types/[fleet, network_type, setting, rpc_response]

type
    SettingsModel* = ref object
        events*: EventEmitter

proc newSettingsModel*(events: EventEmitter): SettingsModel =
  result = SettingsModel()
  result.events = events

proc saveSetting*(self: SettingsModel, key: Setting, value: string | JsonNode | bool): StatusGoError =
    result = statusgo_backend_settings.saveSetting(key, value)

proc getSetting*[T](self: SettingsModel, name: Setting, defaultValue: T, useCached: bool = true): T =
  result = statusgo_backend_settings.getSetting(name, defaultValue, useCached)

proc getSetting*[T](self: SettingsModel, name: Setting, useCached: bool = true): T =
  result = statusgo_backend_settings.getSetting[T](name, useCached)

# TODO: name with a 2 due to namespace conflicts that need to be addressed in subsquent PRs
proc getSetting2*[T](name: Setting, defaultValue: T, useCached: bool = true): T =
  result = statusgo_backend_settings.getSetting(name, defaultValue, useCached)

proc getSetting2*[T](name: Setting, useCached: bool = true): T =
  result = statusgo_backend_settings.getSetting[T](name, useCached)

proc getCurrentNetworkDetails*(self: SettingsModel): NetworkDetails =
  result = statusgo_backend_settings.getCurrentNetworkDetails()

proc getMailservers*(self: SettingsModel):JsonNode =
  result = statusgo_backend_settings.getMailservers()

proc getPinnedMailserver*(self: SettingsModel): string =
  result = statusgo_backend_settings.getPinnedMailserver()

proc pinMailserver*(self: SettingsModel, enode: string = "") =
  statusgo_backend_settings.pinMailserver(enode)

proc saveMailserver*(self: SettingsModel, name, enode: string) =
  statusgo_backend_settings.saveMailserver(name, enode)

proc getFleet*(self: SettingsModel): Fleet =
    result = statusgo_backend_settings.getFleet()

proc getCurrentNetwork*(): NetworkType =
    result = statusgo_backend_settings.getCurrentNetwork()

proc getAllNetworks*(): seq[NetworkDetails] =
  statusgo_backend_settings.getSetting[seq[NetworkDetails]](Setting.Networks_Networks)

proc getCurrentNetwork*(self: SettingsModel): NetworkType =
    result = getCurrentNetwork()

proc setWakuVersion*(self: SettingsModel, newVersion: int) =
  statusgo_backend_settings.setWakuVersion(newVersion)

proc setBloomFilterMode*(self: SettingsModel, bloomFilterMode: bool): StatusGoError =
  statusgo_backend_settings.setBloomFilterMode(bloomFilterMode)

proc setFleet*(self: SettingsModel, fleetConfig: FleetConfig, fleet: Fleet): StatusGoError =
  statusgo_backend_settings.setFleet(fleetConfig, fleet)

proc getNodeConfig*(self: SettingsModel): JsonNode =
  statusgo_backend_settings.getNodeConfig()

proc setBloomLevel*(self: SettingsModel, bloomFilterMode: bool, fullNode: bool): StatusGoError =
  statusgo_backend_settings.setBloomLevel(bloomFilterMode, fullNode)