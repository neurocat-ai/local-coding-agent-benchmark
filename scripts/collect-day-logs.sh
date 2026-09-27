#!/usr/bin/env bash
set -euo pipefail

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
target=".results/day-snapshots/$stamp"
mkdir -p "$target"
date -u +%Y-%m-%dT%H:%M:%SZ > "$target/collected-at.txt"

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi > "$target/nvidia-smi.txt" 2>&1 || true
else
  echo "nvidia-smi unavailable" > "$target/nvidia-smi.txt"
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose ps --all > "$target/compose-ps.txt" 2>&1 || true
  docker compose images > "$target/compose-images.txt" 2>&1 || true
  docker compose logs --no-color --timestamps ollama > "$target/ollama.log" 2>&1 || true
  docker compose logs --no-color --timestamps openhands > "$target/openhands.log" 2>&1 || true
else
  echo "Docker daemon unavailable" > "$target/compose-ps.txt"
fi

echo "Day logs collected: $target"
