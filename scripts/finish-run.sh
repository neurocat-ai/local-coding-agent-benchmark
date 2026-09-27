#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

run_id="${1:?Usage: $0 RUN_ID}"
run_dir=".runs/$run_id"
result_dir=".results/$run_id"
[[ -d "$run_dir/.git" && -d "$result_dir" ]] || { echo "Unknown run: $run_id" >&2; exit 1; }

capture_git_evidence "$run_dir" "$result_dir" "$result_dir"
if command -v dotnet >/dev/null 2>&1 || (command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1); then
  set +e
  scripts/run-tests.sh "$run_dir" 2>&1 | tee "$result_dir/tests-after.txt"
  test_status="${PIPESTATUS[0]}"
  set -e
  if [[ "$test_status" -eq 0 ]]; then
    echo "passed" > "$result_dir/final-test-status.txt"
  else
    echo "failed" > "$result_dir/final-test-status.txt"
  fi
else
  echo "Final test deferred: neither .NET SDK nor a running Docker daemon is available." > "$result_dir/tests-after.txt"
  echo "deferred" > "$result_dir/final-test-status.txt"
fi
printf 'FINISHED_AT=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$result_dir/metadata.env"
scripts/collect-run-logs.sh "$run_id" final >/dev/null
scripts/build-summary.py
echo "Captured results in $result_dir"
