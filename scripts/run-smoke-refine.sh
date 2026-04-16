#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SOURCE_TEXT="${2:-SpeakDock source}"
REFINED_TEXT="${3:-SpeakDock refined}"
SCENARIO="${SMOKE_REFINE_SCENARIO:-success}"
TARGET="${SMOKE_REFINE_TARGET:-compose}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-refine-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
COMMAND_FILE="$WORK_DIR/command.txt"
REQUEST_FILE="$WORK_DIR/request.txt"
CAPTURE_ROOT="$WORK_DIR/capture"
SERVER_LOG="$WORK_DIR/refine-server.log"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
EXPECTED_TEXT="$REFINED_TEXT"
STUB_STATUS_CODE="200"
APP_REFINE_PHASE="submit"
HOST_COMMAND_TEXT=""
HOST_COMMAND_TRIGGER_TEXT=""
EXPECTED_REQUEST_TEXT=""
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
  dirty-undo)
    EXPECTED_TEXT="$SOURCE_TEXT"
    APP_REFINE_PHASE="dirty-undo"
    HOST_COMMAND_TEXT="$REFINED_TEXT edited"
    HOST_COMMAND_TRIGGER_TEXT="$REFINED_TEXT"
    ;;
  fallback)
    EXPECTED_TEXT="$SOURCE_TEXT"
    STUB_STATUS_CODE="500"
    ;;
  submit-observed-edit)
    HOST_COMMAND_TEXT="$SOURCE_TEXT edited"
    HOST_COMMAND_TRIGGER_TEXT="$SOURCE_TEXT"
    EXPECTED_REQUEST_TEXT="$HOST_COMMAND_TEXT"
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

find_capture_file() {
  find "$CAPTURE_ROOT" -type f | head -n 1
}

wait_for_capture_text() {
  local expected_text="$1"
  local capture_file=""
  local actual_text=""

  for _ in {1..50}; do
    capture_file="$(find_capture_file)"
    if [[ -n "$capture_file" && -f "$capture_file" ]]; then
      actual_text="$(cat "$capture_file")"
      if [[ "$actual_text" == "$expected_text" ]]; then
        return 0
      fi
    fi
    sleep 0.1
  done

  return 1
}

print -u2 -- "Launching local refine stub..."
STUB_ARGS=(
  python3
  "$ROOT_DIR/scripts/run-refine-stub-server.py"
  --port "$PORT"
  --response-text "$REFINED_TEXT"
  --status-code "$STUB_STATUS_CODE"
)

if [[ -n "$EXPECTED_REQUEST_TEXT" ]]; then
  STUB_ARGS+=(--record-user-message "$REQUEST_FILE")
fi

"${STUB_ARGS[@]}" >"$SERVER_LOG" 2>&1 &
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

if [[ "$TARGET" == "compose" ]]; then
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

  if [[ -n "$HOST_COMMAND_TEXT" ]]; then
    (
      if wait_for_state_text "$HOST_COMMAND_TRIGGER_TEXT"; then
        print -n -- "$HOST_COMMAND_TEXT" > "$COMMAND_FILE"
      fi
    ) &
    COMMAND_WRITER_PID=$!
  fi
elif [[ "$TARGET" == "capture" ]]; then
  mkdir -p "$CAPTURE_ROOT"

  if [[ -n "$HOST_COMMAND_TEXT" ]]; then
    (
      if wait_for_capture_text "$HOST_COMMAND_TRIGGER_TEXT"; then
        capture_file="$(find_capture_file)"
        if [[ -n "$capture_file" ]]; then
          print -n -- "$HOST_COMMAND_TEXT" > "$capture_file"
        fi
      fi
    ) &
    COMMAND_WRITER_PID=$!
  fi
else
  print -u2 -- "Unknown SMOKE_REFINE_TARGET: $TARGET"
  exit 1
fi

BASE_URL="http://127.0.0.1:$PORT/v1"

print -u2 -- "Running SpeakDock smoke refine ($SCENARIO)..."
OPEN_ARGS=(
  -g
  -n
  -W
  "$APP_PATH"
  --args
  --smoke-refine \
  --smoke-refine-phase "$APP_REFINE_PHASE" \
  --smoke-text "$SOURCE_TEXT" \
  --smoke-delay "1.5" \
  --smoke-refine-base-url "$BASE_URL" \
  --smoke-refine-api-key "smoke-token" \
  --smoke-refine-model "smoke-model"
)

if [[ "$TARGET" == "capture" ]]; then
  OPEN_ARGS+=(
    --smoke-refine-target "capture"
    --smoke-capture-root "$CAPTURE_ROOT"
  )
fi

open "${OPEN_ARGS[@]}"

ACTUAL_TEXT=""
if [[ "$TARGET" == "compose" ]]; then
  if wait_for_state_text "$EXPECTED_TEXT"; then
    ACTUAL_TEXT="$(cat "$STATE_FILE")"
  elif [[ -f "$STATE_FILE" ]]; then
    ACTUAL_TEXT="$(cat "$STATE_FILE")"
  fi
else
  if wait_for_capture_text "$EXPECTED_TEXT"; then
    CAPTURE_FILE="$(find_capture_file)"
    ACTUAL_TEXT="$(cat "$CAPTURE_FILE")"
  else
    CAPTURE_FILE="$(find_capture_file)"
    if [[ -n "$CAPTURE_FILE" && -f "$CAPTURE_FILE" ]]; then
      ACTUAL_TEXT="$(cat "$CAPTURE_FILE")"
    fi
  fi
fi

if [[ "$ACTUAL_TEXT" != "$EXPECTED_TEXT" ]]; then
  print -u2 -- "Smoke refine mismatch ($SCENARIO)."
  print -u2 -- "Expected: $EXPECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

if [[ -n "$EXPECTED_REQUEST_TEXT" ]]; then
  ACTUAL_REQUEST_TEXT=""
  if [[ -f "$REQUEST_FILE" ]]; then
    ACTUAL_REQUEST_TEXT="$(cat "$REQUEST_FILE")"
  fi

  if [[ "$ACTUAL_REQUEST_TEXT" != "$EXPECTED_REQUEST_TEXT" ]]; then
    print -u2 -- "Smoke refine request mismatch ($SCENARIO)."
    print -u2 -- "Expected request text: $EXPECTED_REQUEST_TEXT"
    print -u2 -- "Actual request text:   $ACTUAL_REQUEST_TEXT"
    print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
    exit 1
  fi
fi

if [[ "$SCENARIO" == "fallback" ]]; then
  print -u2 -- "Smoke refine fallback passed."
elif [[ "$SCENARIO" == "dirty-undo" ]]; then
  print -u2 -- "Smoke refine dirty undo passed."
elif [[ "$SCENARIO" == "manual" ]]; then
  print -u2 -- "Smoke manual refine passed."
elif [[ "$SCENARIO" == "submit-observed-edit" ]]; then
  print -u2 -- "Smoke refine submit sync passed."
else
  print -u2 -- "Smoke refine passed."
fi
