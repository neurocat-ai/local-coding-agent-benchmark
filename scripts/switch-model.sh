#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_command curl
require_command python3
model="$(resolve_model "${1:-}")"
wait_for_ollama
python3 scripts/warm-model.py "$model"
printf '%s\n' "$model" > .active-model
echo "Active model: $model"
