import backend_type

type BackendWrapper* = ref object 
    backend*: Backend

proc newBackendWrapperInstance*(): BackendWrapper =
    result = BackendWrapper()
