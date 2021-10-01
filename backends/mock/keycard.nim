import ../types
import ../../status/types/[keycard]

method keycardStart*(self: MockBackend) = discard

method keycardStop*(self: MockBackend) = discard

method keycardSelect*(self: MockBackend): KeycardApplicationInfo =
  result = KeycardApplicationInfo(installed: true)
