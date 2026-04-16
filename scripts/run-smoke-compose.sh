#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SMOKE_TEXT="${2:-SpeakDock smoke}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"

cleanup() {
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to quit' >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

activate_test_host() {
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to activate' >/dev/null 2>&1 || true
  sleep 0.2
}

wait_for_state_text() {
  local expected_text="$1"
  local actual_text=""

  for _ in {1..50}; do
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

print -u2 -- "Launching SpeakDockTestHost..."
open -n "$HOST_APP_PATH" --args --state-file "$STATE_FILE" --ready-file "$READY_FILE"

for _ in {1..50}; do
  [[ -f "$READY_FILE" ]] && break
  sleep 0.1
done

if [[ ! -f "$READY_FILE" ]]; then
  print -u2 -- "SpeakDockTestHost did not become ready."
  exit 1
fi

activate_test_host

print -u2 -- "Running SpeakDock smoke compose..."
open -g -n -W "$APP_PATH" --args --smoke-hot-path --smoke-text "$SMOKE_TEXT" --smoke-delay "1.5"

ACTUAL_TEXT=""
if wait_for_state_text "$SMOKE_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$SMOKE_TEXT" ]]; then
  print -u2 -- "Smoke compose mismatch."
  print -u2 -- "Expected: $SMOKE_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

print -u2 -- "Smoke compose passed."
