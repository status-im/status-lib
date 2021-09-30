mode = ScriptMode.Verbose

version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "WIP refactor to extract business logic from status-desktop into a reusable library"
license       = "MIT"
skipDirs      = @["test"]

requires "nim >= 1.2.0"

import strutils

const release_opts =
  " --define:danger" &
  " --define:strip" &
  " --hints:off" &
  " --opt:size" &
  " --passC:-flto" &
  " --passL:-flto"

const debug_opts =
  " --debugger:native" &
  " --define:chronicles_line_numbers" &
  " --define:debug" &
  " --linetrace:on" &
  " --stacktrace:on"

proc buildAndRun(name: string,
                 srcDir = "test_nim/",
                 outDir = "test_nim/build/",
                 params = "",
                 cmdParams = "",
                 lang = "c") =
  mkDir outDir
  exec "nim " &
    lang &
    (if getEnv("RELEASE").strip != "false": release_opts else: debug_opts) &
    (if defined(windows): " --define:usePcreHeader" else: "") &
    " --define:ssl" &
    " --nimcache:nimcache/" & (if getEnv("RELEASE").strip != "false": "release/" else: "debug/") & name &
    (if getEnv("PCRE_LDFLAGS").strip != "": " --passL:\"" & getEnv("PCRE_LDFLAGS") & "\"" else: "") &
    " --passL:\"-L" & getEnv("STATUSGO_LIBDIR") & " -lstatus \"" &
    " --passL:\"-L" & getEnv("KEYCARDGO_LIBDIR") & " -lkeycard \"" &
    " --out:" & outDir & name &
    " " &
    srcDir & name & ".nim"
  if defined(macosx):
    exec "install_name_tool -add_rpath " & getEnv("STATUSGO_LIBDIR") & " " & outDir & name
    exec "install_name_tool -change " & "libstatus." & getEnv("LIBSTATUS_EXT") & " @rpath/libstatus." & getEnv("LIBSTATUS_EXT") & " " & outDir & name
  if getEnv("RUN_AFTER_BUILD").strip != "false":
    exec outDir & name

task tests, "Build and run all tests":
  rmDir "test_nim/build/"
  buildAndRun "test_all"
