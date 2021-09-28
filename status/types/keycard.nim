type KeycardApplicationInfo* = ref object
  installed*: bool
  initialized*: bool
  instanceUID*: string
  secureChannelPublicKey*: string
  version*:  int64
  availableSlots*: int64
  keyUID*: string
  capabilities*: int64
