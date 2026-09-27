#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 RUN_ID MODEL SHELL [TASK_ID] [REASONING_MODE]" >&2
  echo "Example: $0 qwen-q8-qwen-code-01 qwen36-q8 qwen-code ERP-001 on" >&2
  exit 2
fi
run_id="$1"
model="$2"
agent_shell="$3"
task_id="${4:-ERP-001}"
reasoning_mode="${5:-auto}"
target=".runs/${run_id}"
result_dir=".results/${run_id}"
task_file="experiments/tasks/${task_id}.md"

if [[ ! -f "$task_file" ]]; then
  echo "Unknown task: $task_id (expected $task_file)" >&2
  exit 2
fi

if [[ -e "$target" || -e "$result_dir" ]]; then
  echo "Run already exists: $run_id" >&2
  exit 1
fi
mkdir -p .runs "$result_dir"
mkdir -p "$target"
# Archive copy avoids macOS AppleDouble files (._*) that dotnet may treat as C# sources.
COPYFILE_DISABLE=1 tar \
  --exclude='.DS_Store' \
  --exclude='._*' \
  -C demo/guard-erp -cf - . | tar -C "$target" -xf -
cp "$task_file" "$target/TASK.md"

git -C "$target" init -q
git -C "$target" config user.name "Local Dev Agent Lab"
git -C "$target" config user.email "lab@localhost"
git -C "$target" add .
git -C "$target" commit -qm "Baseline for $run_id"
baseline_commit="$(git -C "$target" rev-parse HEAD)"

cat > "$result_dir/metadata.env" <<EOF
RUN_ID=$run_id
MODEL=$model
SHELL=$agent_shell
TASK_ID=$task_id
REASONING_MODE=$reasoning_mode
SERVER_HOURLY_PRICE=${SERVER_HOURLY_PRICE:-}
COST_CURRENCY=${COST_CURRENCY:-USD}
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
RUN_PATH=$target
BASELINE_COMMIT=$baseline_commit
EOF
cp experiments/result-template.md "$result_dir/review.md"
cp experiments/review-template.json "$result_dir/review.json"
if command -v dotnet >/dev/null 2>&1 || (command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1); then
  scripts/run-tests.sh "$target" > "$result_dir/tests-before.txt" 2>&1 || {
    echo "failed" > "$result_dir/baseline-test-status.txt"
    echo "Baseline tests failed; see $result_dir/tests-before.txt" >&2
    exit 1
  }
  echo "passed" > "$result_dir/baseline-test-status.txt"
else
  echo "Baseline test deferred: neither .NET SDK nor a running Docker daemon is available." > "$result_dir/tests-before.txt"
  echo "deferred" > "$result_dir/baseline-test-status.txt"
fi
scripts/collect-run-logs.sh "$run_id" prepared >/dev/null
printf '%s\n' "$target"
