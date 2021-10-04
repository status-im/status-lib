import ../types
import ../../types/[keycard]

method keycardStart*(self: MockBackend) = discard

method keycardStop*(self: MockBackend) = discard

method keycardSelect*(self: MockBackend): KeycardApplicationInfo =
  result = KeycardApplicationInfo(installed: true)

method keycardPair*(self: MockBackend, pairingPassword: string): KeycardPairingInfo =
  result = KeycardPairingInfo()

method keycardOpenSecureChannel*(self: MockBackend, index: int, key: string) = discard

method keycardVerifyPin*(self: MockBackend, pin: string) = discard

method keycardExportKey*(self: MockBackend): string =
  result = "0x00"
