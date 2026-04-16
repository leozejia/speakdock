#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SOURCE_TEXT="${2:-SpeakDock source}"
REFINED_TEXT="${3:-SpeakDock refined}"
SCENARIO="${SMOKE_REFINE_SCENARIO:-success}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-refine-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
SERVER_LOG="$WORK_DIR/refine-server.log"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
EXPECTED_TEXT="$REFINED_TEXT"
STUB_STATUS_CODE="200"
APP_REFINE_PHASE="submit"
PORT="$(python3 - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

case "$SCENARIO" in
  success)
    ;;
  manual)
    APP_REFINE_PHASE="manual"
    ;;
  fallback)
    EXPECTED_TEXT="$SOURCE_TEXT"
    STUB_STATUS_CODE="500"
    ;;
  *)
    print -u2 -- "Unknown SMOKE_REFINE_SCENARIO: $SCENARIO"
    exit 1
    ;;
esac

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to quit' >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

activate_test_host() {
  osascript -e 'tell application id "com.leozejia.speakdock.testhost" to activate' >/dev/null 2>&1 || true
  sleep 0.2
}

server_ready() {
  python3 - "$PORT" <<'PY'
import socket
import sys

port = int(sys.argv[1])
with socket.socket() as sock:
    sock.settimeout(0.1)
    try:
        sock.connect(("127.0.0.1", port))
    except OSError:
        raise SystemExit(1)
PY
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

print -u2 -- "Launching local refine stub..."
python3 "$ROOT_DIR/scripts/run-refine-stub-server.py" \
  --port "$PORT" \
  --response-text "$REFINED_TEXT" \
  --status-code "$STUB_STATUS_CODE" \
  >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

for _ in {1..50}; do
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    print -u2 -- "Local refine stub exited early."
    cat "$SERVER_LOG" >&2 || true
    exit 1
  fi

  if server_ready; then
    break
  fi

  sleep 0.1
done

if ! server_ready; then
  print -u2 -- "Local refine stub did not become ready."
  cat "$SERVER_LOG" >&2 || true
  exit 1
fi

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

BASE_URL="http://127.0.0.1:$PORT/v1"

print -u2 -- "Running SpeakDock smoke refine ($SCENARIO)..."
open -g -n -W "$APP_PATH" --args \
  --smoke-refine \
  --smoke-refine-phase "$APP_REFINE_PHASE" \
  --smoke-text "$SOURCE_TEXT" \
  --smoke-delay "1.5" \
  --smoke-refine-base-url "$BASE_URL" \
  --smoke-refine-api-key "smoke-token" \
  --smoke-refine-model "smoke-model"

ACTUAL_TEXT=""
if wait_for_state_text "$EXPECTED_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$EXPECTED_TEXT" ]]; then
  print -u2 -- "Smoke refine mismatch ($SCENARIO)."
  print -u2 -- "Expected: $EXPECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

if [[ "$SCENARIO" == "fallback" ]]; then
  print -u2 -- "Smoke refine fallback passed."
elif [[ "$SCENARIO" == "manual" ]]; then
  print -u2 -- "Smoke manual refine passed."
else
  print -u2 -- "Smoke refine passed."
fi
