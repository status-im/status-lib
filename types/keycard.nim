type KeycardException* = ref object of Exception
  error*: string

type KeycardStartException* = ref object of KeycardException

type KeycardStopException* = ref object of KeycardException

type KeycardSelectException* = ref object of KeycardException

type KeycardPINException* = ref object of KeycardException
  pinRetry*: int64

type KeycardApplicationInfo* = ref object
  installed*: bool
  initialized*: bool
  instanceUID*: string
  secureChannelPublicKey*: string
  version*:  int64
  availableSlots*: int64
  keyUID*: string
  capabilities*: int64
