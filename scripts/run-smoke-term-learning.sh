#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
DEFAULT_FIXTURE_PATH="$ROOT_DIR/Tests/SpeakDockMacTests/Fixtures/term-learning-anonymous-baseline.json"
SMOKE_TERM_LEARNING_FIXTURE="${SMOKE_TERM_LEARNING_FIXTURE:-$DEFAULT_FIXTURE_PATH}"
SMOKE_TERM_LEARNING_SCENARIO="${SMOKE_TERM_LEARNING_SCENARIO:-promotion}"
SOURCE_TEXT="${2:-}"
CORRECTED_TEXT="${3:-}"
EVIDENCE_RUNS="${4:-3}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-term-learning-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
COMMAND_FILE="$WORK_DIR/command.txt"
TERM_DICTIONARY_STORAGE="$WORK_DIR/term-dictionary.json"
CYCLES_FILE="$WORK_DIR/cycles.tsv"
FINAL_CHECK_FILE="$WORK_DIR/final-check.tsv"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
FINAL_INPUT_TEXT=""
FINAL_EXPECTED_TEXT=""
SCENARIO_LABEL=""

cleanup() {
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to quit' >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

activate_test_host() {
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to activate' >/dev/null 2>&1 || true
  sleep 0.2
}

write_legacy_scenario_files() {
  : > "$CYCLES_FILE"

  for _ in {1..$EVIDENCE_RUNS}; do
    print -r -- "$SOURCE_TEXT"$'\t'"$CORRECTED_TEXT" >> "$CYCLES_FILE"
  done

  print -r -- "$SOURCE_TEXT"$'\t'"$CORRECTED_TEXT" > "$FINAL_CHECK_FILE"
  SCENARIO_LABEL="legacy"
}

write_fixture_scenario_files() {
  python3 - "$SMOKE_TERM_LEARNING_FIXTURE" "$SMOKE_TERM_LEARNING_SCENARIO" "$CYCLES_FILE" "$FINAL_CHECK_FILE" <<'PY'
import json
import sys

fixture_path, scenario_name, cycles_path, final_check_path = sys.argv[1:]

with open(fixture_path, "r", encoding="utf-8") as handle:
    fixture = json.load(handle)

scenarios = fixture.get("smokeScenarios") or {}
scenario = scenarios.get(scenario_name)
if scenario is None:
    raise SystemExit(f"Missing smoke scenario: {scenario_name}")

cycles = scenario.get("cycles") or []
if not cycles:
    raise SystemExit(f"Smoke scenario has no cycles: {scenario_name}")

with open(cycles_path, "w", encoding="utf-8") as cycles_handle:
    for cycle in cycles:
        generated_text = cycle.get("generatedText", "")
        corrected_text = cycle.get("correctedText", "")
        if not generated_text or not corrected_text:
            raise SystemExit(f"Invalid cycle in scenario: {scenario_name}")
        if any(token in generated_text for token in ("\t", "\n")) or any(token in corrected_text for token in ("\t", "\n")):
            raise SystemExit(f"Unsupported tab/newline in scenario cycle: {scenario_name}")
        cycles_handle.write(f"{generated_text}\t{corrected_text}\n")

final_check = scenario.get("finalCheck") or {}
input_text = final_check.get("inputText", "")
expected_text = final_check.get("expectedText", "")
if not input_text or expected_text == "":
    raise SystemExit(f"Invalid finalCheck in scenario: {scenario_name}")
if any(token in input_text for token in ("\t", "\n")) or any(token in expected_text for token in ("\t", "\n")):
    raise SystemExit(f"Unsupported tab/newline in finalCheck: {scenario_name}")

with open(final_check_path, "w", encoding="utf-8") as final_handle:
    final_handle.write(f"{input_text}\t{expected_text}\n")
PY

  SCENARIO_LABEL="$SMOKE_TERM_LEARNING_SCENARIO"
}

load_scenario_files() {
  if [[ -n "$SOURCE_TEXT" && -n "$CORRECTED_TEXT" ]]; then
    write_legacy_scenario_files
  else
    write_fixture_scenario_files
  fi

  IFS=$'\t' read -r FINAL_INPUT_TEXT FINAL_EXPECTED_TEXT < "$FINAL_CHECK_FILE"
}

wait_for_state_text() {
  local expected_text="$1"
  local actual_text=""

  for _ in {1..80}; do
    if [[ -f "$STATE_FILE" ]]; then
      actual_text="$(cat "$STATE_FILE")"
      if [[ "$actual_text" == "$expected_text" ]]; then
        return 0
      fi
    fi
    sleep 0.1
  done

  return 1
}

set_host_text() {
  local text="$1"
  print -rn -- "$text" > "$COMMAND_FILE"

  if ! wait_for_state_text "$text"; then
    local actual_text=""
    [[ -f "$STATE_FILE" ]] && actual_text="$(cat "$STATE_FILE")"
    print -u2 -- "SpeakDockTestHost text update mismatch."
    print -u2 -- "Expected: $text"
    print -u2 -- "Actual:   $actual_text"
    exit 1
  fi
}

run_learning_cycle() {
  local source_text="$1"
  local corrected_text="$2"

  activate_test_host

  open -g -n -W "$APP_PATH" --args \
    --smoke-term-learning \
    --smoke-text "$source_text" \
    --smoke-delay "0.8" \
    --smoke-submit-delay "1.5" \
    --smoke-term-dictionary-storage "$TERM_DICTIONARY_STORAGE" &
  local launcher_pid=$!

  if ! wait_for_state_text "$source_text"; then
    local actual_text=""
    [[ -f "$STATE_FILE" ]] && actual_text="$(cat "$STATE_FILE")"
    print -u2 -- "Smoke term-learning commit mismatch."
    print -u2 -- "Expected: $source_text"
    print -u2 -- "Actual:   $actual_text"
    exit 1
  fi

  set_host_text "$corrected_text"
  wait "$launcher_pid"
  set_host_text ""
}

print -u2 -- "Launching SpeakDockTestHost..."
open -n "$HOST_APP_PATH" --args \
  --state-file "$STATE_FILE" \
  --ready-file "$READY_FILE" \
  --command-file "$COMMAND_FILE"

for _ in {1..50}; do
  [[ -f "$READY_FILE" ]] && break
  sleep 0.1
done

if [[ ! -f "$READY_FILE" ]]; then
  print -u2 -- "SpeakDockTestHost did not become ready."
  exit 1
fi

load_scenario_files

activate_test_host

TOTAL_CYCLES="$(wc -l < "$CYCLES_FILE" | tr -d ' ')"
print -u2 -- "Running term-learning scenario: $SCENARIO_LABEL"

RUN_INDEX=0
while IFS=$'\t' read -r CYCLE_SOURCE_TEXT CYCLE_CORRECTED_TEXT || [[ -n "${CYCLE_SOURCE_TEXT}${CYCLE_CORRECTED_TEXT}" ]]; do
  RUN_INDEX=$((RUN_INDEX + 1))
  print -u2 -- "Running term-learning evidence cycle $RUN_INDEX/$TOTAL_CYCLES..."
  run_learning_cycle "$CYCLE_SOURCE_TEXT" "$CYCLE_CORRECTED_TEXT"
done < "$CYCLES_FILE"

print -u2 -- "Running final term-dictionary apply check..."
activate_test_host
open -g -n -W "$APP_PATH" --args \
  --smoke-hot-path \
  --smoke-text "$FINAL_INPUT_TEXT" \
  --smoke-delay "0.8" \
  --smoke-term-dictionary-storage "$TERM_DICTIONARY_STORAGE"

ACTUAL_TEXT=""
if wait_for_state_text "$FINAL_EXPECTED_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$FINAL_EXPECTED_TEXT" ]]; then
  print -u2 -- "Smoke term-learning final apply mismatch."
  print -u2 -- "Expected: $FINAL_EXPECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

print -u2 -- "Smoke term-learning passed."
