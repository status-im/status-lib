import types

proc newStatusGoBackendInstance*(): StatusGoBackend =
    result = StatusGoBackend()

export types
import bookmark
export bookmark
