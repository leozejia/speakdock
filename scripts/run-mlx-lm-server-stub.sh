#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST=""
PORT=""
MODEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --model)
      MODEL="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$PORT" || -z "$MODEL" ]]; then
  print -u2 -- "run-mlx-lm-server-stub.sh requires --port and --model."
  exit 1
fi

if [[ -n "$HOST" && "$HOST" != "127.0.0.1" ]]; then
  print -u2 -- "run-mlx-lm-server-stub.sh only supports loopback host 127.0.0.1."
  exit 1
fi

RESPONSE_TEXT="${SPEAKDOCK_MLX_LM_SERVER_STUB_RESPONSE_TEXT:-$MODEL}"
RECORD_USER_MESSAGE="${SPEAKDOCK_MLX_LM_SERVER_STUB_RECORD_USER_MESSAGE:-}"
ADVERTISED_MODEL="${SPEAKDOCK_MLX_LM_SERVER_STUB_ADVERTISED_MODEL:-$MODEL}"

args=(
  "$ROOT_DIR/scripts/run-refine-stub-server.py"
  "--port" "$PORT"
  "--response-text" "$RESPONSE_TEXT"
  "--advertised-model" "$ADVERTISED_MODEL"
)

if [[ -n "$RECORD_USER_MESSAGE" ]]; then
  args+=("--record-user-message" "$RECORD_USER_MESSAGE")
fi

exec python3 "${args[@]}"
