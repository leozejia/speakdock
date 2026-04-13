#!/bin/zsh

set -euo pipefail

LOG_WINDOW="${1:-20m}"

exec /usr/bin/log show \
  --predicate 'subsystem == "com.leozejia.speakdock"' \
  --info \
  --debug \
  --last "$LOG_WINDOW" \
  --style compact
