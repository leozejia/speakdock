#!/bin/zsh

set -euo pipefail

TRACE_WINDOW="${1:-20m}"

exec /usr/bin/log show \
  --predicate 'subsystem == "com.leozejia.speakdock" AND category == "trace"' \
  --info \
  --debug \
  --last "$TRACE_WINDOW" \
  --style compact | /usr/bin/grep 'trace.finish' || true
