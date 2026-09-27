#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

run_id="${1:?Usage: $0 RUN_ID LABEL}"
label="${2:?Usage: $0 RUN_ID LABEL}"
[[ "$label" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid checkpoint label: $label" >&2; exit 2; }
run_dir=".runs/$run_id"
result_dir=".results/$run_id"
checkpoint_dir="$result_dir/checkpoints/$label"
[[ -d "$run_dir/.git" && -d "$result_dir" ]] || { echo "Unknown run: $run_id" >&2; exit 1; }
[[ ! -e "$checkpoint_dir" ]] || { echo "Checkpoint already exists: $label" >&2; exit 1; }

mkdir -p "$checkpoint_dir"
capture_git_evidence "$run_dir" "$checkpoint_dir" "$result_dir"
date -u +%Y-%m-%dT%H:%M:%SZ > "$checkpoint_dir/recorded-at.txt"

if command -v dotnet >/dev/null 2>&1 || (command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1); then
  set +e
  scripts/run-tests.sh "$run_dir" > "$checkpoint_dir/tests.txt" 2>&1
  test_status="$?"
  set -e
  if [[ "$test_status" -eq 0 ]]; then echo "passed"; else echo "failed"; fi > "$checkpoint_dir/test-status.txt"
else
  echo "deferred" > "$checkpoint_dir/test-status.txt"
  echo "Test deferred: neither .NET SDK nor a running Docker daemon is available." > "$checkpoint_dir/tests.txt"
fi

scripts/collect-run-logs.sh "$run_id" "$label" >/dev/null
echo "Checkpoint captured: $run_id / $label"
