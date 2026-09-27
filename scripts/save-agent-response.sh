#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 RUN_ID STAGE [FILE]}"
stage="${2:?Usage: $0 RUN_ID STAGE [FILE]}"
source_file="${3:-}"
[[ "$stage" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid response stage: $stage" >&2; exit 2; }
result_dir=".results/$run_id"
[[ -f "$result_dir/metadata.env" ]] || { echo "Unknown run: $run_id" >&2; exit 1; }
response_dir="$result_dir/agent-responses"
mkdir -p "$response_dir"

if [[ -n "$source_file" ]]; then
  [[ -f "$source_file" ]] || { echo "Response file not found: $source_file" >&2; exit 1; }
  cp "$source_file" "$response_dir/${stage}.txt"
else
  echo "Paste the agent response, then press Ctrl-D:" >&2
  sed 's/\r$//' > "$response_dir/${stage}.txt"
fi
date -u +%Y-%m-%dT%H:%M:%SZ > "$response_dir/${stage}-recorded-at.txt"
echo "Agent response saved: $run_id / $stage"
