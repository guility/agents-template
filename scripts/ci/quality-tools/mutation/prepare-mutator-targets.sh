#!/usr/bin/env bash
set -euo pipefail

uv sync --project scripts/ci/quality-tools --locked --no-dev
bash scripts/setup/fetch_language_templates.sh all
uv sync --project src/templates/python --locked --all-extras
(cd src/templates/nodejs && corepack pnpm install --frozen-lockfile)
cargo fetch --manifest-path src/templates/rust/Cargo.toml --locked
(cd src/templates/go && go mod download)
