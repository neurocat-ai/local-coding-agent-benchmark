#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

action="${1:-}"
run_id="${2:-}"
stage="${3:-autonomous}"
[[ -n "$action" && -n "$run_id" ]] || { echo "Usage: $0 start|stop RUN_ID [STAGE]" >&2; exit 2; }
[[ "$stage" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid timer stage: $stage" >&2; exit 2; }
result_dir=".results/$run_id"
timer_dir="$result_dir/timers"
timer_file="$timer_dir/${stage}-start"
[[ -d "$result_dir" ]] || { echo "Unknown run: $run_id" >&2; exit 1; }
mkdir -p "$timer_dir"

case "$action" in
  start)
    [[ ! -f "$timer_file" ]] || { echo "Timer already running: $run_id / $stage" >&2; exit 1; }
    date +%s > "$timer_file"
    date -u +%Y-%m-%dT%H:%M:%SZ > "$timer_dir/${stage}-started-at.txt"
    echo "Timer started for $run_id / $stage" ;;
  stop)
    [[ -f "$timer_file" ]] || { echo "Timer was not started for $run_id" >&2; exit 1; }
    started="$(cat "$timer_file")"
    finished="$(date +%s)"
    elapsed=$((finished - started))
    echo "$elapsed" > "$timer_dir/${stage}-seconds.txt"
    date -u +%Y-%m-%dT%H:%M:%SZ > "$timer_dir/${stage}-finished-at.txt"
    if [[ "$stage" == "autonomous" ]]; then
      echo "$elapsed" > "$result_dir/task-wall-seconds.txt"
      cp "$timer_dir/${stage}-started-at.txt" "$result_dir/task-started-at.txt"
      cp "$timer_dir/${stage}-finished-at.txt" "$result_dir/task-finished-at.txt"
    fi
    rm "$timer_file"
    echo "Stage duration: $elapsed seconds" ;;
  *) echo "Usage: $0 start|stop RUN_ID [STAGE]" >&2; exit 2 ;;
esac
