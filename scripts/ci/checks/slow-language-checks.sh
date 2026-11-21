#!/usr/bin/env bash
set -euo pipefail

bash scripts/ci/checks/install-uv.sh
export PATH="$UV_INSTALL_DIR:$HOME/.local/bin:$PATH"
uv sync --project src/templates/python --locked --all-extras
uv run --project src/templates/python mypy src/templates/python/src

corepack enable
(cd src/templates/nodejs && pnpm install --frozen-lockfile && pnpm lint && pnpm build)
cargo +1.100.0 clippy --manifest-path src/templates/rust/Cargo.toml --locked --all-targets -- -D warnings

go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.8.0
GOLANGCI="$(go env GOPATH)/bin/golangci-lint"
(cd src/templates/go && "$GOLANGCI" run ./...)

dotnet restore src/templates/csharp/DDDTemplate.Tests.csproj --locked-mode
(cd src/templates/csharp && dotnet format whitespace --verify-no-changes)
(cd src/templates/csharp && dotnet format analyzers --verify-no-changes)
