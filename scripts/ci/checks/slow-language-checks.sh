#!/usr/bin/env bash
set -euo pipefail

nuget_cache="$(mktemp -d)"
trap 'rm -rf "$nuget_cache"' EXIT
export NUGET_PACKAGES="$nuget_cache/packages"
export NUGET_HTTP_CACHE_PATH="$nuget_cache/http-cache"

bash scripts/ci/checks/install-uv.sh
export PATH="$UV_INSTALL_DIR:$HOME/.local/bin:$PATH"
uv sync --project src/templates/python --locked --all-extras
uv run --project src/templates/python mypy src/templates/python/src

corepack enable
(cd src/templates/nodejs && pnpm install --frozen-lockfile && pnpm lint && pnpm build)

dotnet restore src/templates/csharp/DDDTemplate.Tests.csproj --locked-mode --force --no-cache
(cd src/templates/csharp && dotnet format whitespace --verify-no-changes)
(cd src/templates/csharp && dotnet format analyzers --verify-no-changes)
