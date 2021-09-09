# TODO: Import all the files that contain {.exportc.}
import status/status

proc helloWorld() {.exportc, dynlib.} =
 echo "hello world"

