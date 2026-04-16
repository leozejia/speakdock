#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SOURCE_TEXT="${2:-project adults 已经完成}"
CORRECTED_TEXT="${3:-Project Atlas 已经完成}"
EVIDENCE_RUNS="${4:-3}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-term-learning-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
COMMAND_FILE="$WORK_DIR/command.txt"
TERM_DICTIONARY_STORAGE="$WORK_DIR/term-dictionary.json"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"

cleanup() {
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to quit' >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

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
  open -g -n -W "$APP_PATH" --args \
    --smoke-term-learning \
    --smoke-text "$SOURCE_TEXT" \
    --smoke-delay "0.8" \
    --smoke-submit-delay "1.5" \
    --smoke-term-dictionary-storage "$TERM_DICTIONARY_STORAGE" &
  local launcher_pid=$!

  if ! wait_for_state_text "$SOURCE_TEXT"; then
    local actual_text=""
    [[ -f "$STATE_FILE" ]] && actual_text="$(cat "$STATE_FILE")"
    print -u2 -- "Smoke term-learning commit mismatch."
    print -u2 -- "Expected: $SOURCE_TEXT"
    print -u2 -- "Actual:   $actual_text"
    exit 1
  fi

  set_host_text "$CORRECTED_TEXT"
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

for ((run_index = 1; run_index <= EVIDENCE_RUNS; run_index++)); do
  print -u2 -- "Running term-learning evidence cycle $run_index/$EVIDENCE_RUNS..."
  run_learning_cycle
done

print -u2 -- "Running final term-dictionary apply check..."
open -g -n -W "$APP_PATH" --args \
  --smoke-hot-path \
  --smoke-text "$SOURCE_TEXT" \
  --smoke-delay "0.8" \
  --smoke-term-dictionary-storage "$TERM_DICTIONARY_STORAGE"

ACTUAL_TEXT=""
if wait_for_state_text "$CORRECTED_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$CORRECTED_TEXT" ]]; then
  print -u2 -- "Smoke term-learning final apply mismatch."
  print -u2 -- "Expected: $CORRECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

print -u2 -- "Smoke term-learning passed."
