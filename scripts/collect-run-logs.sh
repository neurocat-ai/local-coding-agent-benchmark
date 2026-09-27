#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

run_id="${1:?Usage: $0 RUN_ID LABEL}"
label="${2:?Usage: $0 RUN_ID LABEL}"
[[ "$label" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid log label: $label" >&2; exit 2; }
result_dir=".results/$run_id"
metadata_file="$result_dir/metadata.env"
[[ -f "$metadata_file" ]] || { echo "Unknown run: $run_id" >&2; exit 1; }
log_dir="$result_dir/logs/$label"
mkdir -p "$log_dir"

started_at="$(sed -n 's/^STARTED_AT=//p' "$metadata_file" | tail -n 1)"
collected_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '%s\n' "$collected_at" > "$log_dir/collected-at.txt"

{
  uname -a
  uptime
  df -h .
  if command -v free >/dev/null 2>&1; then free -h; fi
} > "$log_dir/host.txt" 2>&1 || true

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=timestamp,name,driver_version,memory.total,memory.used,memory.free,utilization.gpu,utilization.memory,power.draw,temperature.gpu \
    --format=csv,noheader,nounits > "$log_dir/gpu.txt" 2>&1 || true
  nvidia-smi -q > "$log_dir/nvidia-smi-q.txt" 2>&1 || true
else
  echo "nvidia-smi unavailable" > "$log_dir/gpu.txt"
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose ps --all > "$log_dir/compose-ps.txt" 2>&1 || true
  docker compose images > "$log_dir/compose-images.txt" 2>&1 || true
  if [[ -n "$started_at" ]]; then
    docker compose logs --no-color --timestamps --since "$started_at" ollama > "$log_dir/ollama.log" 2>&1 || true
    docker compose logs --no-color --timestamps --since "$started_at" openhands > "$log_dir/openhands.log" 2>&1 || true
  else
    docker compose logs --no-color --timestamps ollama > "$log_dir/ollama.log" 2>&1 || true
    docker compose logs --no-color --timestamps openhands > "$log_dir/openhands.log" 2>&1 || true
  fi
  docker compose exec -T ollama ollama ps > "$log_dir/ollama-ps.txt" 2>&1 || true
  docker compose exec -T ollama ollama list > "$log_dir/ollama-list.txt" 2>&1 || true
else
  echo "Docker daemon unavailable" > "$log_dir/compose-ps.txt"
fi

echo "Run logs collected: $run_id / $label"
