#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
DURATION="${2:-30}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/speakdock-compose-probe.XXXXXX")"
RESULT_FILE="$WORK_DIR/result.txt"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

print -u2 -- "Launching compose probe for ${DURATION}s."
print -u2 -- "Focus target app input fields while the probe runs, then inspect with: make logs LOG_WINDOW=2m"
open -n -W "$APP_PATH" --args --probe-compose --probe-compose-duration "$DURATION" --probe-compose-result-file "$RESULT_FILE"

if [[ ! -f "$RESULT_FILE" ]]; then
  print -u2 -- "Compose probe did not produce a verdict."
  print -u2 -- "Inspect with: make logs LOG_WINDOW=2m"
  exit 1
fi

VERDICT="$(tr -d '[:space:]' < "$RESULT_FILE")"

case "$VERDICT" in
  available)
    print -u2 -- "Compose probe verdict: available"
    ;;
  no-target)
    print -u2 -- "Compose probe verdict: no-target"
    ;;
  unavailable)
    print -u2 -- "Compose probe verdict: unavailable"
    print -u2 -- "Inspect with: make logs LOG_WINDOW=2m"
    exit 1
    ;;
  *)
    print -u2 -- "Compose probe verdict: unknown ($VERDICT)"
    print -u2 -- "Inspect with: make logs LOG_WINDOW=2m"
    exit 1
    ;;
esac
