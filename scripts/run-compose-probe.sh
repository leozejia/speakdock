#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
DURATION="${2:-30}"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"

print -u2 -- "Launching compose probe for ${DURATION}s."
print -u2 -- "Focus target app input fields while the probe runs, then inspect with: make logs LOG_WINDOW=2m"
exec open -n -W "$APP_PATH" --args --probe-compose --probe-compose-duration "$DURATION"
