#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_command docker
require_command curl
require_command nvidia-smi

echo "== Host GPU =="
nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version --format=csv,noheader
echo "== Docker GPU access =="
docker compose config --quiet
docker compose up -d ollama postgres
wait_for_ollama
docker compose exec -T ollama nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo "== Services =="
docker compose ps
echo "== Models =="
docker compose exec -T ollama ollama list
curl --fail --silent --show-error "http://127.0.0.1:${OLLAMA_PORT}/v1/models" >/dev/null
echo "All server checks passed."
