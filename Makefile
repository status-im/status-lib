# Copyright (c) 2021 Status Research & Development GmbH. Licensed under
# either of:
# - Apache License, version 2.0
# - MIT license
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

SHELL := bash # the shell used internally by Make

# used inside the included makefiles
BUILD_SYSTEM_DIR := vendor/nimbus-build-system

# we don't want an error here, so we can handle things later, in the ".DEFAULT" target
-include $(BUILD_SYSTEM_DIR)/makefiles/variables.mk

.PHONY: \
	all \
	bottles \
	clean \
	deps \
	libstatuslib \
	status-go \
	update \
	build_ctest \
	ctest \
	test

ifeq ($(NIM_PARAMS),)
# "variables.mk" was not included, so we update the submodules.
GIT_SUBMODULE_UPDATE := git submodule update --init --recursive
.DEFAULT:
	+@ echo -e "Git submodules not found. Running '$(GIT_SUBMODULE_UPDATE)'.\n"; \
		$(GIT_SUBMODULE_UPDATE); \
		echo
# Now that the included *.mk files appeared, and are newer than this file, Make will restart itself:
# https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles
#
# After restarting, it will execute its original goal, so we don't have to start a child Make here
# with "$(MAKE) $(MAKECMDGOALS)". Isn't hidden control flow great?

else # "variables.mk" was included. Business as usual until the end of this file.

all: libstatuslib

# must be included after the default target
-include $(BUILD_SYSTEM_DIR)/makefiles/targets.mk

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
 detected_OS := Windows
else
 detected_OS := $(strip $(shell uname))
endif

ifeq ($(detected_OS),Darwin)
 CFLAGS := -mmacosx-version-min=10.14
 export CFLAGS
 CGO_CFLAGS := -mmacosx-version-min=10.14
 export CGO_CFLAGS
 LIBSTATUS_EXT := dylib
 MACOSX_DEPLOYMENT_TARGET := 10.14
 export MACOSX_DEPLOYMENT_TARGET
else ifeq ($(detected_OS),Windows)
 LIBSTATUS_EXT := dll
else
 LIBSTATUS_EXT := so
endif

# ifeq ($(detected_OS),Darwin)
# BOTTLES_DIR := $(shell pwd)/bottles
# BOTTLES := $(addprefix $(BOTTLES_DIR)/,openssl@1.1 pcre)
#
# $(BOTTLES): | $(BOTTLES_DIR)
# 	echo -e "\e[92mFetching:\e[39m $(notdir $@) bottle"
# 	./scripts/fetch-brew-bottle.sh $(notdir $@)
#
# $(BOTTLES_DIR):
# 	echo -e "\e[92mUpdating:\e[39m macOS Homebrew"
# 	if [[ $$(stat -f %u /usr/local/var/homebrew) -ne "$${UID}" ]]; then \
# 		echo "Missing permissions to update Homebrew formulae!" >&2; \
# 	else \
# 		brew update >/dev/null; \
# 		mkdir -p $(BOTTLES_DIR); \
# 	fi
#
# bottles: $(BOTTLES)
# endif

deps: | deps-common bottles

update: | update-common


RELEASE ?= false
ifeq ($(RELEASE),false)
 # We need `-d:debug` to get Nim's default stack traces
 NIM_PARAMS += -d:debug
 # Enable debugging symbols in DOtherSide, in case we need GDB backtraces
 CFLAGS += -g
 CXXFLAGS += -g
else
 # Additional optimization flags for release builds are not included at present;
 # adding them will involve refactoring config.nims in the root of this repo
 NIM_PARAMS += -d:release
endif

NIM_PARAMS += --outdir:./build

STATUSGO := vendor/status-go/build/bin/libstatus.$(LIBSTATUS_EXT)
STATUSGO_LIBDIR := $(shell pwd)/$(shell dirname "$(STATUSGO)")
export STATUSGO
export STATUSGO_LIBDIR
export LIBSTATUS_EXT

status-go: $(STATUSGO)
$(STATUSGO): | deps
	echo -e $(BUILD_MSG) "status-go"
	+ cd vendor/status-go && \
	  $(MAKE) statusgo-shared-library $(HANDLE_OUTPUT)

LIBSTATUSLIB := build/libstatuslib.$(LIBSTATUS_EXT).0
libstatuslib: | $(STATUSGO) 
	echo -e $(BUILD_MSG) "$@" && \
		$(ENV_SCRIPT) nim c $(NIM_PARAMS) $(NIM_EXTRA_PARAMS) --passL:"-L$(STATUSGO_LIBDIR)" --passL:"-lstatus" -o:build/$@.$(LIBSTATUS_EXT).0 -d:ssl --app:lib --noMain --header --nimcache:nimcache/libstatuslib statuslib.nim && \
		rm -f build/$@.$(LIBSTATUS_EXT) && \
		ln -s $@.$(LIBSTATUS_EXT).0 build/$@.$(LIBSTATUS_EXT) && \
		cp nimcache/libstatuslib/statuslib.h build/statuslib.h.for-reference-only && \
		[[ $$? = 0 ]]

# libraries for dynamic linking of non-Nim objects
EXTRA_LIBS_DYNAMIC := -L"$(CURDIR)/build" -lstatuslib -lm -L"$(STATUSGO_LIBDIR)" -lstatus
build_ctest: | $(LIBSTATUSLIB) build deps
	echo -e $(BUILD_MSG) "build/ctest" && \
		 $(CC) test/main.c -Wl,-rpath,'$$ORIGIN' -Iinclude/ $(EXTRA_LIBS_DYNAMIC) -g -o build/ctest

LD_LIBRARY_PATH_NIMBLE := $${LD_LIBRARY_PATH}
ifneq ($(detected_OS),Windows)
 ifneq ($(detected_OS),Darwin)
  LD_LIBRARY_PATH_NIMBLE := $(STATUSGO_LIBDIR):$(LD_LIBRARY_PATH_NIMBLE)
 endif
endif

PATH_NIMBLE := $${PATH}
ifeq ($(detected_OS),Windows)
 PATH_NIMBLE := $(STATUSGO_LIBDIR):$(PATH_NIMBLE)
endif

NIMBLE_ENV = \
	RELEASE=$(RELEASE)
ifeq ($(detected_OS),Windows)
 NIMBLE_ENV += PATH="$(PATH_NIMBLE)"
 PCRE_LDFLAGS := -L$(shell cygpath -m /ucrt64/lib) -lpcre
 NIMBLE_ENV += PCRE_LDFLAGS="$(PCRE_LDFLAGS)"
else ifneq ($(detected_OS),Darwin)
 NIMBLE_ENV += LD_LIBRARY_PATH="$(LD_LIBRARY_PATH_NIMBLE)"
endif

ctest: | build_ctest
	echo -e "Running ctest:" && \
	LD_LIBRARY_PATH="$(STATUSGO_LIBDIR)" \
	./build/ctest

test: | $(STATUSGO)
	$(NIMBLE_ENV) $(ENV_SCRIPT) nimble tests

clean: | clean-common
	rm -rf bin/* node_modules bottles/* pkg/* tmp/* $(STATUSGO)

endif # "variables.mk" was not included
