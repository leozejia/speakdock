SHELL := /bin/zsh
CONFIGURATION ?= debug
LOG_WINDOW ?= 20m
TRACE_WINDOW ?= 20m
PROBE_SECONDS ?= 30
ROOT_DIR := $(CURDIR)
SWIFT_HOME := $(ROOT_DIR)/.swift-home
SWIFT_CACHE := $(ROOT_DIR)/.swift-cache
CLANG_MODULE_CACHE := $(SWIFT_CACHE)/clang/ModuleCache
SWIFT_ENV := HOME=$(SWIFT_HOME) XDG_CACHE_HOME=$(SWIFT_CACHE) CLANG_MODULE_CACHE_PATH=$(CLANG_MODULE_CACHE) SWIFTPM_MODULECACHE_OVERRIDE=$(CLANG_MODULE_CACHE)
TEST_FILTER ?=

.PHONY: build run clean test logs traces probe-compose smoke-compose smoke-refine

build:
	./scripts/build-app.sh $(CONFIGURATION)

run:
	./scripts/run-dev.sh $(CONFIGURATION)

logs:
	./scripts/show-logs.sh $(LOG_WINDOW)

traces:
	./scripts/show-traces.sh $(TRACE_WINDOW)

probe-compose:
	./scripts/run-compose-probe.sh $(CONFIGURATION) $(PROBE_SECONDS)

smoke-compose:
	./scripts/run-smoke-compose.sh $(CONFIGURATION)

smoke-refine:
	./scripts/run-smoke-refine.sh $(CONFIGURATION)

test:
	mkdir -p $(SWIFT_HOME) $(CLANG_MODULE_CACHE)
	$(SWIFT_ENV) swift test $(if $(TEST_FILTER),--filter $(TEST_FILTER),)

clean:
	rm -rf .build .swift-cache .swift-home
