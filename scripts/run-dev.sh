#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"

print -u2 -- "Launching $APP_PATH"
exec open -n -W "$APP_PATH"
