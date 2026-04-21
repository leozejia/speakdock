#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${1:-python3}"
FIXTURE_PATH="${2:-$ROOT_DIR/Tests/SpeakDockMacTests/Fixtures/asr-post-correction-anonymous-baseline.json}"
RESULTS_PATH="${3:-$ROOT_DIR/.tmp/asr-post-correction-results.json}"
PROMPT_PROFILE="${4:-fewshot_terms_homophone}"
ENV_FILE="${SPEAKDOCK_ENV_FILE:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

BASE_URL="${ASR_POST_CORRECTION_OPENAI_BASE_URL:-}"
MODEL="${ASR_POST_CORRECTION_OPENAI_MODEL:-}"
API_KEY="${OPENAI_API_KEY:-}"

if [[ -z "$BASE_URL" || -z "$MODEL" || -z "$API_KEY" ]]; then
  print -u2 -- "Missing remote eval config. Fill .env with ASR_POST_CORRECTION_OPENAI_BASE_URL, ASR_POST_CORRECTION_OPENAI_MODEL, and OPENAI_API_KEY."
  exit 1
fi

"$PYTHON_BIN" "$ROOT_DIR/scripts/run-asr-post-correction-eval.py" \
  --fixture "$FIXTURE_PATH" \
  --results "$RESULTS_PATH" \
  --base-url "$BASE_URL" \
  --api-key "$API_KEY" \
  --model "$MODEL" \
  --prompt-profile "$PROMPT_PROFILE"
