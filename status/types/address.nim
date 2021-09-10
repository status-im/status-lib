import
  web3/[conversions, ethtypes]

export conversions, ethtypes

type SavedAddress* = ref object
  name*: string
  address*: Address
  chainId*: int