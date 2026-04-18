#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
APP_PATH="$("$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION")"
ASR_CORRECTION_BASE_URL="${SPEAKDOCK_ASR_CORRECTION_BASE_URL:-}"
ASR_CORRECTION_API_KEY="${SPEAKDOCK_ASR_CORRECTION_API_KEY:-}"
ASR_CORRECTION_MODEL="${SPEAKDOCK_ASR_CORRECTION_MODEL:-}"

print -u2 -- "Launching $APP_PATH"
if [[ -n "$ASR_CORRECTION_BASE_URL" && -n "$ASR_CORRECTION_API_KEY" && -n "$ASR_CORRECTION_MODEL" ]]; then
  exec open -W "$APP_PATH" --args \
    --asr-correction-base-url "$ASR_CORRECTION_BASE_URL" \
    --asr-correction-api-key "$ASR_CORRECTION_API_KEY" \
    --asr-correction-model "$ASR_CORRECTION_MODEL"
fi

exec open -W "$APP_PATH"
