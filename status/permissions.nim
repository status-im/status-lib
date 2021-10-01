import json
import sets
import chronicles
import ./statusgo_backend/permissions as status_permissions
import ./types/permission
import ../eventemitter

logScope:
  topics = "permissions-model"

type
    PermissionsModel* = ref object
      events*: EventEmitter

proc newPermissionsModel*(events: EventEmitter): PermissionsModel =
  result = PermissionsModel()
  result.events = events

proc init*(self: PermissionsModel) =
  discard

proc getDapps*(self: PermissionsModel): seq[Dapp] =
  return status_permissions.getDapps()

proc getPermissions*(self: PermissionsModel, dapp: string): HashSet[Permission] =
  return status_permissions.getPermissions(dapp)

proc revoke*(self: PermissionsModel, permission: Permission) =
  status_permissions.revoke(permission)

proc hasPermission*(self: PermissionsModel, dapp: string, permission: Permission): bool =
  return self.getPermissions(dapp).contains(permission)

proc addPermission*(self: PermissionsModel, dapp: string, permission: Permission) =
  status_permissions.addPermission(dapp, permission)

proc revokePermission*(self: PermissionsModel, dapp: string, permission: Permission) =
  status_permissions.revokePermission(dapp, permission)

proc clearPermissions*(self: PermissionsModel, dapp: string) =
  status_permissions.clearPermissions(dapp)

proc clearPermissions*(self: PermissionsModel) =
  for dapps in status_permissions.getDapps():
    status_permissions.clearPermissions(dapps.name)
