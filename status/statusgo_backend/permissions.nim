import json
import strutils
import sets
import chronicles
import sequtils
import ../types/permission

import ./core

proc getDapps*(): seq[Dapp] =
  let response = core.callPrivateRPC("permissions_getDappPermissions")
  result = @[]
  for dapps in response.parseJson["result"].getElems():
    var dapp = Dapp(
      name: dapps["dapp"].getStr(),
      permissions: initHashSet[Permission]()
    )
    for permission in dapps["permissions"].getElems():
        dapp.permissions.incl(permission.getStr().toPermission())
    result.add(dapp)

proc getPermissions*(dapp: string): HashSet[Permission] =
  let response = core.callPrivateRPC("permissions_getDappPermissions")
  result = initHashSet[Permission]()
  for dappPermission in response.parseJson["result"].getElems():
    if dappPermission["dapp"].getStr() == dapp:
      if not dappPermission.hasKey("permissions"): return
      for permission in dappPermission["permissions"].getElems():
        result.incl(permission.getStr().toPermission())

proc revoke*(permission: Permission) =
  let response = core.callPrivateRPC("permissions_getDappPermissions")
  var permissions = initHashSet[Permission]()

  for dapps in response.parseJson["result"].getElems():
    for currPerm in dapps["permissions"].getElems():
      let p = currPerm.getStr().toPermission()
      if p != permission:
        permissions.incl(p)

    discard core.callPrivateRPC("permissions_addDappPermissions", %*[{
      "dapp": dapps["dapp"].getStr(),
      "permissions": permissions.toSeq()
    }])

proc addPermission*(dapp: string, permission: Permission) =
  var permissions = getPermissions(dapp)
  permissions.incl(permission)
  discard callPrivateRPC("permissions_addDappPermissions", %*[{
    "dapp": dapp,
    "permissions": permissions.toSeq()
  }])

proc revokePermission*(dapp: string, permission: Permission) =
  var permissions = getPermissions(dapp)
  permissions.excl(permission)

  if permissions.len == 0:
    discard core.callPrivateRPC("permissions_deleteDappPermissions", %*[dapp])
  else:
    discard core.callPrivateRPC("permissions_addDappPermissions", %*[{
      "dapp": dapp,
      "permissions": permissions.toSeq()
    }])

proc clearPermissions*(dapp: string) =
  discard core.callPrivateRPC("permissions_deleteDappPermissions", %*[dapp])
