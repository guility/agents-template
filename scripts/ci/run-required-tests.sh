#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
language="${1:-${TEST_LANGUAGE:-python}}"
suite="${2:-all}"
project="$root/src/templates/$language"
bash "$root/scripts/setup/fetch_language_templates.sh" "$language"
[[ -d "$project" ]] || { echo "Language package is missing: $project" >&2; exit 2; }

case "$language" in
  python)
    uv sync --python 3.14 --locked --all-extras --project "$project"
    ;;
  nodejs)
    corepack enable
    (cd "$project" && corepack pnpm install --frozen-lockfile)
    ;;
  rust)
    export RUSTUP_TOOLCHAIN=1.100.0
    rustup toolchain install 1.100.0 --profile minimal
    cargo fetch --manifest-path "$project/Cargo.toml" --locked
    cargo install cargo-mutants --version 27.1.0 --locked
    ;;
  go)
    (cd "$project" && go mod download)
    GREMLINS_INSTALL_DIR="${HOME}/.local/bin" bash "$root/scripts/ci/checks/install-gremlins.sh"
    export PATH="${HOME}/.local/bin:$PATH"
    ;;
  csharp)
    (cd "$project" && dotnet restore DDDTemplate.Tests.csproj --locked-mode)
    (cd "$project" && dotnet tool restore --tool-manifest .config/dotnet-tools.json)
    ;;
  *) echo "Unsupported required-test language: $language" >&2; exit 2 ;;
esac

export PROJECT_ROOT="$project"
export TEST_LANGUAGE="$language"
case "$suite" in
  all)
    for runner in unit integration mutation e2e; do
      bash "$root/scripts/ci/test-$runner.sh"
    done
    ;;
  post-merge)
    for runner in integration e2e mutation; do
      bash "$root/scripts/ci/test-$runner.sh"
    done
    ;;
  unit|integration|mutation|e2e)
    bash "$root/scripts/ci/test-$suite.sh"
    ;;
  *) echo "Unsupported required-test suite: $suite (expected all, post-merge, unit, integration, mutation, or e2e)" >&2; exit 2 ;;
esac
