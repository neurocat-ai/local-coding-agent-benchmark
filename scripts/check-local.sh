#!/usr/bin/env bash
set -euo pipefail
lab_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$lab_root"

failed=0
for command_name in bash curl python3 tar; do
  if ! command -v "$command_name" >/dev/null 2>&1; then echo "MISSING: $command_name"; failed=1; fi
done
for path in compose.yaml .env.example agent-runtimes/qwen-code/settings.example.json \
  models/qwen36-q8/Modelfile models/qwen36-q4/Modelfile models/qwen36-coding-q4/Modelfile \
  models/gpt-oss-120b/Modelfile models/gpt-oss-20b/Modelfile \
  demo/guard-erp/AGENTS.md demo/guard-erp/TASK.md \
  experiments/tasks/ERP-001.md experiments/tasks/ERP-003.md \
  experiments/tasks/ERP-004.md experiments/benchmark-protocol.md \
  experiments/review-template.json scripts/build-summary.py scripts/checkpoint-run.sh \
  scripts/capture-agent-session.sh scripts/collect-run-logs.sh \
  scripts/collect-day-logs.sh scripts/save-agent-response.sh \
  experiments/test-matrix.csv; do
  if [[ ! -f "$path" ]]; then echo "MISSING FILE: $path"; failed=1; fi
done
python3 -m json.tool agent-runtimes/qwen-code/settings.example.json >/dev/null
python3 -m json.tool experiments/review-template.json >/dev/null
python3 -c 'import ast, pathlib; [ast.parse(pathlib.Path(p).read_text()) for p in ("scripts/build-summary.py", "scripts/benchmark-api.py", "scripts/warm-model.py")]'
bash -n scripts/*.sh
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose config --quiet
else
  echo "NOTE: Docker is not running locally; Compose rendering was skipped."
fi
if (( failed != 0 )); then exit 1; fi
echo "Local static checks passed."
