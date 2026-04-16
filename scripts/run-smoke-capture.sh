#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
SMOKE_TEXT="${2:-SpeakDock capture smoke}"
SMOKE_CAPTURE_SCENARIO="${SMOKE_CAPTURE_SCENARIO:-continue}"
SMOKE_CONTINUED_TEXT="${SMOKE_CAPTURE_CONTINUED_TEXT:-again}"
SMOKE_EDITED_TEXT="${SMOKE_CAPTURE_EDITED_TEXT:-$SMOKE_TEXT edited}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-capture-smoke.XXXXXX")"
CAPTURE_ROOT="$WORK_DIR/capture"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
EXPECTED_TEXT="$SMOKE_EDITED_TEXT
$SMOKE_CONTINUED_TEXT"

cleanup() {
  if [[ -n "${EDITOR_PID:-}" ]]; then
    kill "$EDITOR_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

find_capture_file() {
  find "$CAPTURE_ROOT" -type f | head -n 1
}

wait_for_capture_contents() {
  local expected_text="$1"
  local capture_file=""
  local actual_text=""

  for _ in {1..80}; do
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

case "$SMOKE_CAPTURE_SCENARIO" in
  continue)
    ;;
  undo)
    EXPECTED_TEXT=""
    ;;
  *)
    print -u2 -- "Unknown SMOKE_CAPTURE_SCENARIO: $SMOKE_CAPTURE_SCENARIO"
    exit 1
    ;;
esac

mkdir -p "$CAPTURE_ROOT"

if [[ "$SMOKE_CAPTURE_SCENARIO" == "continue" ]]; then
  (
    if wait_for_capture_contents "$SMOKE_TEXT"; then
      capture_file="$(find_capture_file)"
      if [[ -n "$capture_file" ]]; then
        print -n -- "$SMOKE_EDITED_TEXT" > "$capture_file"
      fi
    fi
  ) &
  EDITOR_PID=$!
fi

print -u2 -- "Running SpeakDock smoke capture ($SMOKE_CAPTURE_SCENARIO)..."
OPEN_ARGS=(
  -g
  -n
  -W
  "$APP_PATH"
  --args
  --smoke-hot-path
  --smoke-text "$SMOKE_TEXT"
  --smoke-capture-root "$CAPTURE_ROOT"
  --smoke-delay "1.5"
)

if [[ "$SMOKE_CAPTURE_SCENARIO" == "continue" ]]; then
  OPEN_ARGS+=(
    --smoke-hot-path-phase "capture-continue-after-observed-edit"
    --smoke-text-2 "$SMOKE_CONTINUED_TEXT"
  )
elif [[ "$SMOKE_CAPTURE_SCENARIO" == "undo" ]]; then
  OPEN_ARGS+=(
    --smoke-hot-path-phase "capture-undo-recent-submission"
  )
fi

open "${OPEN_ARGS[@]}"

CAPTURE_FILE="$(find_capture_file)"
ACTUAL_TEXT=""
if [[ -n "$CAPTURE_FILE" && -f "$CAPTURE_FILE" ]]; then
  ACTUAL_TEXT="$(cat "$CAPTURE_FILE")"
fi

if [[ "$ACTUAL_TEXT" != "$EXPECTED_TEXT" ]]; then
  print -u2 -- "Smoke capture mismatch ($SMOKE_CAPTURE_SCENARIO)."
  print -u2 -- "Expected: $EXPECTED_TEXT"
  print -u2 -- "Actual:   $ACTUAL_TEXT"
  print -u2 -- "Inspect traces with: make traces TRACE_WINDOW=5m"
  exit 1
fi

if [[ "$SMOKE_CAPTURE_SCENARIO" == "undo" ]]; then
  print -u2 -- "Smoke capture undo passed."
else
  print -u2 -- "Smoke capture continuation passed."
fi
