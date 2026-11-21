#!/usr/bin/env bash
set -euo pipefail

language="${1:?usage: prepare-mutator-language.sh language}"
bash scripts/setup/fetch_language_templates.sh "$language"
case "$language" in
  python) uv sync --project "src/templates/$language" --locked --all-extras ;;
  nodejs)
    corepack enable
    (cd "src/templates/$language" && corepack pnpm install --frozen-lockfile)
    ;;
  rust)
    rustup toolchain install 1.100.0 --profile minimal
    cargo fetch --manifest-path "src/templates/$language/Cargo.toml" --locked
    ;;
  go) (cd "src/templates/$language" && go mod download) ;;
  *) echo "Unsupported Mutator language: $language" >&2; exit 2 ;;
esac
