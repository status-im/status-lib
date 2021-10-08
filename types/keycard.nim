type KeycardException* = ref object of Exception
  error*: string

type KeycardStartException* = ref object of KeycardException

type KeycardStopException* = ref object of KeycardException

type KeycardSelectException* = ref object of KeycardException

type KeycardPairException* = ref object of KeycardException

type KeycardOpenSecureChannelException* = ref object of KeycardException

type KeycardGetStatusException* = ref object of KeycardException

type KeycardUnpairException* = ref object of KeycardException

type KeycardGenerateKeyException* = ref object of KeycardException

type KeycardVerifyPINException* = ref object of KeycardException
  remainingAttempts*: int64

type KeycardExportKeyException* = ref object of KeycardException

type KeycardApplicationInfo* = ref object
  installed*: bool
  initialized*: bool
  instanceUID*: string
  secureChannelPublicKey*: string
  version*:  int64
  availableSlots*: int64
  keyUID*: string
  capabilities*: int64

type KeycardPairingInfo* = ref object
  key*: string
  index*: int64

type KeycardStatus* = ref object
  pinRetryCount*: int64
  pukRetryCount *: int64
  keyInitialized*: bool
  path*: string

type KeycardExportedKey* = ref object
  privKey*: string
  pubKey*: string
  address*: string

