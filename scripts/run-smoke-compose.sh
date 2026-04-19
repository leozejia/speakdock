#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SMOKE_TEXT="${2:-SpeakDock smoke}"
SMOKE_COMPOSE_SCENARIO="${SMOKE_COMPOSE_SCENARIO:-commit}"
SMOKE_CONTINUED_TEXT="${SMOKE_COMPOSE_CONTINUED_TEXT:-again}"
SMOKE_EDITED_TEXT="${SMOKE_COMPOSE_EDITED_TEXT:-$SMOKE_TEXT edited }"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
COMMAND_FILE="$WORK_DIR/command.txt"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
EXPECTED_TEXT="$SMOKE_TEXT"

cleanup() {
  if [[ -n "${COMMAND_WRITER_PID:-}" ]]; then
    kill "$COMMAND_WRITER_PID" >/dev/null 2>&1 || true
  fi
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
open -n "$HOST_APP_PATH" --args --state-file "$STATE_FILE" --ready-file "$READY_FILE" --command-file "$COMMAND_FILE"

for _ in {1..50}; do
  [[ -f "$READY_FILE" ]] && break
  sleep 0.1
done

if [[ ! -f "$READY_FILE" ]]; then
  print -u2 -- "SpeakDockTestHost did not become ready."
  exit 1
fi

activate_test_host

OPEN_ARGS=(
  -g
  -n
  -W
  "$APP_PATH"
  --args
  --smoke-hot-path
  --smoke-text "$SMOKE_TEXT"
  --smoke-delay "1.5"
)

if [[ "$SMOKE_COMPOSE_SCENARIO" == "continue" ]]; then
  EXPECTED_TEXT="$SMOKE_EDITED_TEXT$SMOKE_CONTINUED_TEXT"
  OPEN_ARGS+=(
    --smoke-hot-path-phase "continue-after-observed-edit"
    --smoke-text-2 "$SMOKE_CONTINUED_TEXT"
  )

  (
    if wait_for_state_text "$SMOKE_TEXT"; then
      print -rn -- "$SMOKE_EDITED_TEXT" > "$COMMAND_FILE"
    fi
  ) &
  COMMAND_WRITER_PID=$!
elif [[ "$SMOKE_COMPOSE_SCENARIO" == "undo" ]]; then
  EXPECTED_TEXT=""
  OPEN_ARGS+=(
    --smoke-hot-path-phase "undo-recent-submission"
  )
fi

print -u2 -- "Running SpeakDock smoke compose..."
open "${OPEN_ARGS[@]}"

ACTUAL_TEXT=""
if [[ "$SMOKE_COMPOSE_SCENARIO" == "undo" ]]; then
  if wait_for_state_text "$SMOKE_TEXT" && wait_for_state_text "$EXPECTED_TEXT"; then
    ACTUAL_TEXT="$(cat "$STATE_FILE")"
  elif [[ -f "$STATE_FILE" ]]; then
    ACTUAL_TEXT="$(cat "$STATE_FILE")"
  fi
elif wait_for_state_text "$EXPECTED_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$EXPECTED_TEXT" ]]; then
  print -u2 -- "Smoke compose mismatch."
  print -u2 -- "Expected: $EXPECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

if [[ "$SMOKE_COMPOSE_SCENARIO" == "continue" ]]; then
  print -u2 -- "Smoke compose continuation passed."
elif [[ "$SMOKE_COMPOSE_SCENARIO" == "undo" ]]; then
  print -u2 -- "Smoke compose undo passed."
else
  print -u2 -- "Smoke compose passed."
fi
