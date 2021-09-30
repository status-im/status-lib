import ../types
import ../../status/types/[keycard]

method keycardStart*(self: MockBackend): string =
  result = "Hello Keycard"

method keycardStop*(self: MockBackend): string =
  result = "Hello Keycard"

method keycardSelect*(self: MockBackend): KeycardApplicationInfo =
  result = KeycardApplicationInfo()
