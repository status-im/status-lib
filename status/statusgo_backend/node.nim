import json, strutils

import ../utils
import ../types/fleet
import ./constants as constants

proc getNetworkConfig(currentNetwork: string): JsonNode =
  result = constants.DEFAULT_NETWORKS.first("id", currentNetwork)

proc getDefaultNodeConfig*(fleetConfig: FleetConfig, installationId: string): JsonNode =
  let networkConfig = getNetworkConfig(constants.DEFAULT_NETWORK_NAME)
  let upstreamUrl = networkConfig["config"]["UpstreamConfig"]["URL"]
  let fleet = Fleet.PROD
  
  var newDataDir = networkConfig["config"]["DataDir"].getStr
  newDataDir.removeSuffix("_rpc")
  result = constants.NODE_CONFIG.copy()
  result["ClusterConfig"]["Fleet"] = newJString($fleet)
  result["ClusterConfig"]["BootNodes"] = %* fleetConfig.getNodes(fleet, FleetNodes.Bootnodes)
  result["ClusterConfig"]["TrustedMailServers"] = %* fleetConfig.getNodes(fleet, FleetNodes.Mailservers)
  result["ClusterConfig"]["StaticNodes"] = %* fleetConfig.getNodes(fleet, FleetNodes.Whisper)
  result["ClusterConfig"]["RendezvousNodes"] = %* fleetConfig.getNodes(fleet, FleetNodes.Rendezvous)
  result["NetworkId"] = networkConfig["config"]["NetworkId"]
  result["DataDir"] = newDataDir.newJString()
  result["UpstreamConfig"]["Enabled"] = networkConfig["config"]["UpstreamConfig"]["Enabled"]
  result["UpstreamConfig"]["URL"] = upstreamUrl
  result["ShhextConfig"]["InstallationID"] = newJString(installationId)

  # TODO: fleet.status.im should have different sections depending on the node type
  #       or maybe it's not necessary because a node has the identify protocol
  result["ClusterConfig"]["RelayNodes"] =  %* fleetConfig.getNodes(fleet, FleetNodes.Waku)
  result["ClusterConfig"]["StoreNodes"] =  %* fleetConfig.getNodes(fleet, FleetNodes.Waku)
  result["ClusterConfig"]["FilterNodes"] =  %* fleetConfig.getNodes(fleet, FleetNodes.Waku)
  result["ClusterConfig"]["LightpushNodes"] =  %* fleetConfig.getNodes(fleet, FleetNodes.Waku)

  # TODO: commented since it's not necessary (we do the connections thru C bindings). Enable it thru an option once status-nodes are able to be configured in desktop
  # result["ListenAddr"] = if existsEnv("STATUS_PORT"): newJString("0.0.0.0:" & $getEnv("STATUS_PORT")) else: newJString("0.0.0.0:30305")