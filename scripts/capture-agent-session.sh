#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 RUN_ID -- COMMAND [ARG ...]}"
shift
[[ "${1:-}" == "--" ]] || { echo "Usage: $0 RUN_ID -- COMMAND [ARG ...]" >&2; exit 2; }
shift
[[ $# -gt 0 ]] || { echo "Missing agent command" >&2; exit 2; }

result_dir=".results/$run_id"
[[ -f "$result_dir/metadata.env" ]] || { echo "Unknown run: $run_id" >&2; exit 1; }
run_dir=".runs/$run_id"
[[ -d "$run_dir" ]] || { echo "Missing run directory: $run_dir" >&2; exit 1; }
session_dir="$result_dir/agent-session"
mkdir -p "$session_dir"
transcript="$(cd "$session_dir" && pwd)/terminal.log"
printf '%q ' "$@" > "$session_dir/command.txt"
printf '\n' >> "$session_dir/command.txt"
date -u +%Y-%m-%dT%H:%M:%SZ > "$session_dir/started-at.txt"

set +e
if script --version >/dev/null 2>&1; then
  printf -v command_line '%q ' "$@"
  (cd "$run_dir" && script -q -f -e -c "$command_line" "$transcript")
  exit_status="$?"
else
  (cd "$run_dir" && script -q "$transcript" "$@")
  exit_status="$?"
fi
set -e

date -u +%Y-%m-%dT%H:%M:%SZ > "$session_dir/finished-at.txt"
printf '%s\n' "$exit_status" > "$session_dir/exit-status.txt"
exit "$exit_status"
