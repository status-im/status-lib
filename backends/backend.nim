from ./types import Backend, StatusGoBackend, MockBackend
export Backend, StatusGoBackend, MockBackend

from base/keycard as keycard_methods import keycardStart, keycardStop, keycardSelect, keycardPair,
  keycardOpenSecureChannel, keycardVerifyPin, keycardExportKey
export keycardStart, keycardStop, keycardSelect, keycardPair,
  keycardOpenSecureChannel, keycardVerifyPin, keycardExportKey

import statusgo/keycard as statusgo_keycard
import mock/keycard as mock_keycard

proc newBackend*(name: string): Backend =
  if name == "statusgo":
    result = StatusGoBackend()
  elif name == "mock":
    result = MockBackend()
  else:
    raise newException(ValueError, "unknown backend")
