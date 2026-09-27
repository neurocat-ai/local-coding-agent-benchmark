#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
target="${1:-demo/guard-erp}"
target="$(cd "$target" && pwd)"

if command -v dotnet >/dev/null 2>&1; then
  (cd "$target" && dotnet test GuardErp.sln --nologo)
else
  require_command docker
  docker run --rm \
    -v "$target:/workspace" \
    -v local-dev-agent-nuget:/root/.nuget/packages \
    -w /workspace mcr.microsoft.com/dotnet/sdk:8.0 \
    dotnet test GuardErp.sln --nologo
fi
