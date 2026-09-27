#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_command docker
require_command curl

requested="${1:-all}"
docker compose up -d ollama
wait_for_ollama
pull_and_create() {
  local source_model="$1" profile="$2" modelfile="$3"
  echo "Downloading $source_model"
  docker compose exec -T ollama ollama pull "$source_model"
  docker compose exec -T ollama ollama create "$profile" -f "$modelfile"
}
case "$requested" in
  all)
    pull_and_create "$QWEN_MODEL_SOURCE" "$QWEN_MODEL_PROFILE" /profiles/qwen36-q8/Modelfile
    pull_and_create "$GPTOSS_MODEL_SOURCE" "$GPTOSS_MODEL_PROFILE" /profiles/gpt-oss-120b/Modelfile ;;
  qwen|qwen-q8|qwen36-q8)
    pull_and_create "$QWEN_MODEL_SOURCE" "$QWEN_MODEL_PROFILE" /profiles/qwen36-q8/Modelfile ;;
  qwen-q4|qwen36-q4)
    pull_and_create "$QWEN_Q4_MODEL_SOURCE" "$QWEN_Q4_MODEL_PROFILE" /profiles/qwen36-q4/Modelfile ;;
  qwen-coding-q4|qwen36-coding-q4)
    pull_and_create "$QWEN_CODING_Q4_MODEL_SOURCE" "$QWEN_CODING_Q4_MODEL_PROFILE" /profiles/qwen36-coding-q4/Modelfile ;;
  gpt-oss|gptoss|gpt-oss-120b)
    pull_and_create "$GPTOSS_MODEL_SOURCE" "$GPTOSS_MODEL_PROFILE" /profiles/gpt-oss-120b/Modelfile ;;
  gpt-oss-20b|gptoss-20b)
    pull_and_create "$GPTOSS_LITE_MODEL_SOURCE" "$GPTOSS_LITE_MODEL_PROFILE" /profiles/gpt-oss-20b/Modelfile ;;
  *) echo "Usage: $0 [all|qwen|gpt-oss|qwen-q4|qwen-coding-q4|gpt-oss-20b]" >&2; exit 2 ;;
esac
docker compose exec -T ollama ollama list
