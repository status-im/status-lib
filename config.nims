if defined(macosx):
  switch("passL", "-rpath " & getEnv("STATUSGO_LIBDIR"))
  if hostCPU == "arm64": # Crosscompiling to amd64 since arm64 is not supported
    switch("cpu", "amd64")
    switch("os", "MacOSX")
    switch("passL", "-arch x86_64")
    switch("passC", "-arch x86_64")
