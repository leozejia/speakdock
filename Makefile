SHELL := /bin/zsh
CONFIGURATION ?= debug
LOG_WINDOW ?= 20m
TRACE_WINDOW ?= 20m
ASR_EVAL_THRESHOLD ?= 20
ASR_POST_CORRECTION_PYTHON ?= $(if $(wildcard ./.tmp/asr-eval-venv/bin/python),./.tmp/asr-eval-venv/bin/python,python3)
ASR_POST_CORRECTION_FIXTURE ?= ./Tests/SpeakDockMacTests/Fixtures/asr-post-correction-anonymous-baseline.json
ASR_POST_CORRECTION_RESULTS ?= ./.tmp/asr-post-correction-results.json
ASR_POST_CORRECTION_MODEL ?= ./.tmp/models/Qwen3.5-2B-OptiQ-4bit
ASR_POST_CORRECTION_PROMPT_PROFILE ?= fewshot
PROBE_SECONDS ?= 30
ROOT_DIR := $(CURDIR)
SWIFT_HOME := $(ROOT_DIR)/.swift-home
SWIFT_CACHE := $(ROOT_DIR)/.swift-cache
CLANG_MODULE_CACHE := $(SWIFT_CACHE)/clang/ModuleCache
SWIFT_ENV := HOME=$(SWIFT_HOME) XDG_CACHE_HOME=$(SWIFT_CACHE) CLANG_MODULE_CACHE_PATH=$(CLANG_MODULE_CACHE) SWIFTPM_MODULECACHE_OVERRIDE=$(CLANG_MODULE_CACHE)
TEST_FILTER ?=

.PHONY: build run clean test logs speech-logs traces trace-report speech-error-report asr-correction-report asr-sample-report asr-post-correction-eval asr-post-correction-eval-report term-learning-report probe-compose smoke-compose smoke-compose-continue smoke-compose-undo smoke-compose-switch-undo smoke-capture-continue smoke-capture-undo smoke-asr-correction smoke-refine smoke-refine-manual smoke-capture-refine-manual smoke-refine-dirty-undo smoke-capture-refine-dirty-undo smoke-refine-fallback smoke-capture-refine-fallback smoke-refine-submit-sync smoke-term-learning smoke-term-learning-conflict

build:
	./scripts/build-app.sh $(CONFIGURATION)

run:
	./scripts/run-dev.sh $(CONFIGURATION)

logs:
	./scripts/show-logs.sh $(LOG_WINDOW)

speech-logs:
	./scripts/show-speech-logs.sh $(LOG_WINDOW)

traces:
	./scripts/show-traces.sh $(TRACE_WINDOW)

trace-report:
	python3 ./scripts/report-traces.py --last $(TRACE_WINDOW)

speech-error-report:
	python3 ./scripts/report-speech-errors.py --last $(LOG_WINDOW)

asr-correction-report:
	python3 ./scripts/report-asr-correction.py --last $(LOG_WINDOW)

asr-sample-report:
	python3 ./scripts/report-speech-errors.py --last $(LOG_WINDOW)
	python3 ./scripts/report-asr-correction.py --last $(LOG_WINDOW) --min-samples $(ASR_EVAL_THRESHOLD)

asr-post-correction-eval-report:
	python3 ./scripts/report-asr-post-correction-eval.py --fixture $(ASR_POST_CORRECTION_FIXTURE) --results $(ASR_POST_CORRECTION_RESULTS)

asr-post-correction-eval:
	$(ASR_POST_CORRECTION_PYTHON) ./scripts/run-asr-post-correction-eval.py --fixture $(ASR_POST_CORRECTION_FIXTURE) --results $(ASR_POST_CORRECTION_RESULTS) --model-path $(ASR_POST_CORRECTION_MODEL) --prompt-profile $(ASR_POST_CORRECTION_PROMPT_PROFILE)

term-learning-report:
	python3 ./scripts/report-term-learning.py $(if $(TERM_DICTIONARY_STORAGE),--storage $(TERM_DICTIONARY_STORAGE),)

probe-compose:
	./scripts/run-compose-probe.sh $(CONFIGURATION) $(PROBE_SECONDS)

smoke-compose:
	./scripts/run-smoke-compose.sh $(CONFIGURATION)

smoke-compose-continue:
	SMOKE_COMPOSE_SCENARIO=continue ./scripts/run-smoke-compose.sh $(CONFIGURATION)

smoke-compose-undo:
	SMOKE_COMPOSE_SCENARIO=undo ./scripts/run-smoke-compose.sh $(CONFIGURATION)

smoke-compose-switch-undo:
	SMOKE_COMPOSE_SCENARIO=switch-undo ./scripts/run-smoke-compose.sh $(CONFIGURATION)

smoke-capture-continue:
	SMOKE_CAPTURE_SCENARIO=continue ./scripts/run-smoke-capture.sh $(CONFIGURATION)

smoke-capture-undo:
	SMOKE_CAPTURE_SCENARIO=undo ./scripts/run-smoke-capture.sh $(CONFIGURATION)

smoke-asr-correction:
	./scripts/run-smoke-asr-correction.sh $(CONFIGURATION)

smoke-refine:
	./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-refine-manual:
	SMOKE_REFINE_SCENARIO=manual ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-capture-refine-manual:
	SMOKE_REFINE_TARGET=capture SMOKE_REFINE_SCENARIO=manual ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-refine-dirty-undo:
	SMOKE_REFINE_SCENARIO=dirty-undo ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-capture-refine-dirty-undo:
	SMOKE_REFINE_TARGET=capture SMOKE_REFINE_SCENARIO=dirty-undo ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-refine-fallback:
	SMOKE_REFINE_SCENARIO=fallback ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-capture-refine-fallback:
	SMOKE_REFINE_TARGET=capture SMOKE_REFINE_SCENARIO=manual-fallback ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-refine-submit-sync:
	SMOKE_REFINE_SCENARIO=submit-observed-edit ./scripts/run-smoke-refine.sh $(CONFIGURATION)

smoke-term-learning:
	./scripts/run-smoke-term-learning.sh $(CONFIGURATION)

smoke-term-learning-conflict:
	SMOKE_TERM_LEARNING_SCENARIO=conflict ./scripts/run-smoke-term-learning.sh $(CONFIGURATION)

test:
	mkdir -p $(SWIFT_HOME) $(CLANG_MODULE_CACHE)
	$(SWIFT_ENV) swift test $(if $(TEST_FILTER),--filter $(TEST_FILTER),)

clean:
	rm -rf .build .swift-cache .swift-home
