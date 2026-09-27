#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_command python3
model="$(resolve_model "${1:-qwen}")"
python3 scripts/benchmark-api.py --model "$model" --prompt "Reply with exactly: READY" --label "smoke-${model}"
