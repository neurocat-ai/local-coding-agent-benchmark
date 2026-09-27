#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
scripts/collect-day-logs.sh
scripts/build-summary.py
mkdir -p artifacts
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="artifacts/local-dev-agent-results-${stamp}.tar.gz"
tar -czf "$archive" \
  .results \
  experiments/test-matrix.csv \
  experiments/scoring-guide.md \
  experiments/day2-openhands-handoff.md \
  experiments/day2-openhands-reasoning-decision.md \
  experiments/methodology-reconciliation.md \
  artifacts/infrastructure/openhands116-preflight \
  artifacts/infrastructure/openhands-day2-final
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$archive" > "${archive}.sha256"
else
  shasum -a 256 "$archive" > "${archive}.sha256"
fi
echo "$archive"
