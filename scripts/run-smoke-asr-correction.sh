#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SOURCE_TEXT="${2:-${SMOKE_ASR_CORRECTION_SOURCE_TEXT:-project adults 已经完成}}"
CORRECTED_TEXT="${3:-${SMOKE_ASR_CORRECTION_CORRECTED_TEXT:-Project Atlas 已经完成}}"
PROVIDER="${SMOKE_ASR_CORRECTION_PROVIDER:-custom-endpoint}"
MODEL_IDENTIFIER="${SMOKE_ASR_CORRECTION_MODEL:-smoke-model}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-asr-correction-smoke.XXXXXX")"
STATE_FILE="$WORK_DIR/text.txt"
READY_FILE="$WORK_DIR/ready.txt"
COMMAND_FILE="$WORK_DIR/command.txt"
REQUEST_FILE="$WORK_DIR/request.txt"
SERVER_LOG="$WORK_DIR/asr-correction-server.log"
HOST_APP_PATH="$("$ROOT_DIR/scripts/build-test-host.sh" "$CONFIGURATION")"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
MLX_STUB_EXECUTABLE="$ROOT_DIR/scripts/run-mlx-lm-server-stub.sh"
PORT="$(python3 - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

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

make_on_device_stub_launcher() {
  local launcher_path="$WORK_DIR/mlx-lm-server-smoke-launcher.sh"
  cat >"$launcher_path" <<EOF
#!/bin/zsh
export SPEAKDOCK_MLX_LM_SERVER_STUB_RESPONSE_TEXT=${(q)CORRECTED_TEXT}
export SPEAKDOCK_MLX_LM_SERVER_STUB_RECORD_USER_MESSAGE=${(q)REQUEST_FILE}
exec ${(q)MLX_STUB_EXECUTABLE} "\$@"
EOF
  chmod +x "$launcher_path"
  print -- "$launcher_path"
}

launch_custom_endpoint_stub() {
  print -u2 -- "Launching local ASR correction stub..."
  python3 \
    "$ROOT_DIR/scripts/run-refine-stub-server.py" \
    --port "$PORT" \
    --response-text "$CORRECTED_TEXT" \
    --record-user-message "$REQUEST_FILE" >"$SERVER_LOG" 2>&1 &
  SERVER_PID=$!

  for _ in {1..50}; do
    if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
      print -u2 -- "Local ASR correction stub exited early."
      cat "$SERVER_LOG" >&2 || true
      exit 1
    fi

    if server_ready; then
      break
    fi

    sleep 0.1
  done

  if ! server_ready; then
    print -u2 -- "Local ASR correction stub did not become ready."
    cat "$SERVER_LOG" >&2 || true
    exit 1
  fi
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

BASE_URL="http://127.0.0.1:$PORT/v1"

case "$PROVIDER" in
  custom|custom-endpoint)
    launch_custom_endpoint_stub

    print -u2 -- "Running SpeakDock smoke ASR correction with custom endpoint provider..."
    open -g -n -W "$APP_PATH" --args \
      --smoke-asr-correction \
      --smoke-text "$SOURCE_TEXT" \
      --smoke-delay "1.5" \
      --asr-correction-provider "custom-endpoint" \
      --asr-correction-base-url "$BASE_URL" \
      --asr-correction-api-key "smoke-token" \
      --asr-correction-model "$MODEL_IDENTIFIER"
    ;;
  on-device|onDevice)
    if [[ ! -x "$MLX_STUB_EXECUTABLE" ]]; then
      print -u2 -- "On-device mlx_lm.server stub is unavailable: $MLX_STUB_EXECUTABLE"
      exit 1
    fi

    ON_DEVICE_STUB_LAUNCHER="$(make_on_device_stub_launcher)"
    print -u2 -- "Running SpeakDock smoke ASR correction with on-device provider..."
    open -g -n -W "$APP_PATH" --args \
      --smoke-asr-correction \
      --smoke-text "$SOURCE_TEXT" \
      --smoke-delay "1.5" \
      --asr-correction-provider "on-device" \
      --asr-correction-base-url "$BASE_URL" \
      --asr-correction-model "$MODEL_IDENTIFIER" \
      --on-device-asr-correction-executable "$ON_DEVICE_STUB_LAUNCHER"
    ;;
  *)
    print -u2 -- "Unsupported SMOKE_ASR_CORRECTION_PROVIDER: $PROVIDER"
    exit 1
    ;;
esac

ACTUAL_TEXT=""
if wait_for_state_text "$CORRECTED_TEXT"; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
elif [[ -f "$STATE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$STATE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$CORRECTED_TEXT" ]]; then
  print -u2 -- "Smoke ASR correction compose mismatch."
  print -u2 -- "Expected: $CORRECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect logs with: make speech-logs LOG_WINDOW=5m"
  exit 1
fi

REQUEST_TEXT=""
if [[ -f "$REQUEST_FILE" ]]; then
  REQUEST_TEXT="$(cat "$REQUEST_FILE")"
fi

if [[ "$REQUEST_TEXT" != "$SOURCE_TEXT" ]]; then
  print -u2 -- "Smoke ASR correction request mismatch."
  print -u2 -- "Expected request: $SOURCE_TEXT"
  print -u2 -- "Actual request:   $REQUEST_TEXT"
  exit 1
fi

print -u2 -- "Smoke ASR correction passed."
