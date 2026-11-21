#!/usr/bin/env bash
set -euo pipefail

nuget_cache="$(mktemp -d)"
trap 'rm -rf "$nuget_cache"' EXIT
export NUGET_PACKAGES="$nuget_cache/packages"
export NUGET_HTTP_CACHE_PATH="$nuget_cache/http-cache"
status_root="${QUALITY_STATUS_ROOT:-artifacts/reports/quality}"

write_lint_status() {
  local component="$1" result="$2"
  mkdir -p "$status_root/lint/slow"
  printf '%s\n' "$result" > "$status_root/lint/slow/$component.status"
}

write_lint_status python failed
bash scripts/ci/checks/install-uv.sh
export PATH="$UV_INSTALL_DIR:$HOME/.local/bin:$PATH"
uv sync --project src/templates/python --locked --all-extras
uv run --project src/templates/python mypy src/templates/python/src
write_lint_status python passed

write_lint_status nodejs failed
corepack enable
(cd src/templates/nodejs && pnpm install --frozen-lockfile && pnpm lint && pnpm build)
write_lint_status nodejs passed

write_lint_status csharp failed
dotnet restore src/templates/csharp/DDDTemplate.Tests.csproj --locked-mode --force --no-cache
(cd src/templates/csharp && dotnet format whitespace --verify-no-changes)
(cd src/templates/csharp && dotnet format analyzers --verify-no-changes)
write_lint_status csharp passed
