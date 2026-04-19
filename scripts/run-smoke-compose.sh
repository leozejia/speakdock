#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SMOKE_TEXT="${2:-SpeakDock smoke}"
SMOKE_COMPOSE_SCENARIO="${SMOKE_COMPOSE_SCENARIO:-commit}"
SMOKE_CONTINUED_TEXT="${SMOKE_COMPOSE_CONTINUED_TEXT:-again}"
SMOKE_EDITED_TEXT="${SMOKE_COMPOSE_EDITED_TEXT:-$SMOKE_TEXT edited }"
SMOKE_SWITCHED_TEXT="${SMOKE_COMPOSE_SWITCHED_TEXT:-again}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
COMMAND_FILE="$WORK_DIR/command.txt"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
EXPECTED_TEXT="$SMOKE_TEXT"
EXPECTED_PRIMARY_TEXT="$SMOKE_TEXT"
EXPECTED_SECONDARY_TEXT=""

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

wait_for_state_lines() {
  local expected_primary="$1"
  local expected_secondary="$2"
  local actual_primary=""
  local actual_secondary=""

  for _ in {1..80}; do
    if [[ -f "$STATE_FILE" ]]; then
      actual_primary="$(sed -n '1p' "$STATE_FILE")"
      actual_secondary="$(sed -n '2p' "$STATE_FILE")"
      if [[ "$actual_primary" == "$expected_primary" && "$actual_secondary" == "$expected_secondary" ]]; then
        return 0
      fi
    fi
    sleep 0.1
  done

  return 1
}

set_host_focus() {
  local field="$1"
  print -rn -- "__focus__:${field}" > "$COMMAND_FILE"
  sleep 0.2
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
elif [[ "$SMOKE_COMPOSE_SCENARIO" == "switch-undo" ]]; then
  OPEN_ARGS+=(
    --smoke-hot-path-phase "switch-target-undo-recent-submission"
    --smoke-text-2 "$SMOKE_SWITCHED_TEXT"
  )
fi

print -u2 -- "Running SpeakDock smoke compose..."
if [[ "$SMOKE_COMPOSE_SCENARIO" == "switch-undo" ]]; then
  (
    if wait_for_state_text "$SMOKE_TEXT"; then
      set_host_focus "secondary"
    fi
  ) &
  COMMAND_WRITER_PID=$!
fi

open "${OPEN_ARGS[@]}"

ACTUAL_TEXT=""
if [[ "$SMOKE_COMPOSE_SCENARIO" == "undo" ]]; then
  if wait_for_state_text "$SMOKE_TEXT" && wait_for_state_text "$EXPECTED_TEXT"; then
    ACTUAL_TEXT="$(cat "$STATE_FILE")"
  elif [[ -f "$STATE_FILE" ]]; then
    ACTUAL_TEXT="$(cat "$STATE_FILE")"
  fi
elif [[ "$SMOKE_COMPOSE_SCENARIO" == "switch-undo" ]]; then
  ACTUAL_PRIMARY_TEXT=""
  ACTUAL_SECONDARY_TEXT=""
  if wait_for_state_lines "$EXPECTED_PRIMARY_TEXT" "$EXPECTED_SECONDARY_TEXT"; then
    ACTUAL_PRIMARY_TEXT="$(sed -n '1p' "$STATE_FILE")"
    ACTUAL_SECONDARY_TEXT="$(sed -n '2p' "$STATE_FILE")"
  elif [[ -f "$STATE_FILE" ]]; then
    ACTUAL_PRIMARY_TEXT="$(sed -n '1p' "$STATE_FILE")"
    ACTUAL_SECONDARY_TEXT="$(sed -n '2p' "$STATE_FILE")"
  fi
elif wait_for_state_text "$EXPECTED_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$SMOKE_COMPOSE_SCENARIO" == "switch-undo" ]]; then
  if [[ "$ACTUAL_PRIMARY_TEXT" != "$EXPECTED_PRIMARY_TEXT" || "$ACTUAL_SECONDARY_TEXT" != "$EXPECTED_SECONDARY_TEXT" ]]; then
    print -u2 -- "Smoke compose switch undo mismatch."
    print -u2 -- "Expected primary:   $EXPECTED_PRIMARY_TEXT"
    print -u2 -- "Actual primary:     $ACTUAL_PRIMARY_TEXT"
    print -u2 -- "Expected secondary: $EXPECTED_SECONDARY_TEXT"
    print -u2 -- "Actual secondary:   $ACTUAL_SECONDARY_TEXT"
    print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
    exit 1
  fi
elif [[ "$ACTUAL_TEXT" != "$EXPECTED_TEXT" ]]; then
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
elif [[ "$SMOKE_COMPOSE_SCENARIO" == "switch-undo" ]]; then
  print -u2 -- "Smoke compose switch undo passed."
else
  print -u2 -- "Smoke compose passed."
fi
