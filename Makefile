SHELL := /bin/zsh
CONFIGURATION ?= debug
ROOT_DIR := $(CURDIR)
SWIFT_HOME := $(ROOT_DIR)/.swift-home
SWIFT_CACHE := $(ROOT_DIR)/.swift-cache
CLANG_MODULE_CACHE := $(SWIFT_CACHE)/clang/ModuleCache
SWIFT_ENV := HOME=$(SWIFT_HOME) XDG_CACHE_HOME=$(SWIFT_CACHE) CLANG_MODULE_CACHE_PATH=$(CLANG_MODULE_CACHE) SWIFTPM_MODULECACHE_OVERRIDE=$(CLANG_MODULE_CACHE)
TEST_FILTER ?=

.PHONY: build run clean test

build:
	./scripts/build-app.sh $(CONFIGURATION)

run:
	./scripts/run-dev.sh $(CONFIGURATION)

test:
	mkdir -p $(SWIFT_HOME) $(CLANG_MODULE_CACHE)
	$(SWIFT_ENV) swift test $(if $(TEST_FILTER),--filter $(TEST_FILTER),)

clean:
	rm -rf .build .swift-cache .swift-home
