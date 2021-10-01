import ../../types/[keycard]
import ../types

method keycardStart*(self: Backend) =
  raise newException(ValueError, "No implementation available")

method keycardStop*(self: Backend) =
  raise newException(ValueError, "No implementation available")

method keycardSelect*(self: Backend): KeycardApplicationInfo =
  raise newException(ValueError, "No implementation available")
