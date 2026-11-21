#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
base="${1:-${GITHUB_EVENT_BEFORE:-}}"
head="${2:-${GITHUB_SHA:-HEAD}}"
base="$(bash "$root/scripts/common/git/resolve-diff-base.sh" "$head" "$base")"
mapfile -t files < <(git -C "$root" diff --name-only "$base" "$head")
contains() { printf '%s\n' "${files[@]}" | grep -Eq "$1"; }
if contains '\.(py|js|jsx|ts|tsx|rs|go|cs)$' && ! command -v lizard >/dev/null; then
  python3 -m pip install --user lizard==1.25.0
fi
if contains '\.py$|(^|/)(pyproject\.toml|uv\.lock|ruff\.toml|\.ruff\.toml)$'; then
  command -v ruff >/dev/null || python3 -m pip install --user ruff==0.17.6
fi
if contains '\.(js|jsx|ts|tsx)$|(^|/)(package\.json|package-lock\.json|pnpm-lock\.yaml|\.prettierrc([^/]*)|prettier\.config\.[^/]+|\.editorconfig|\.prettierignore)$'; then
  command -v prettier >/dev/null || npm install --global prettier@3.6.2
fi
if contains '\.rs$|(^|/)(Cargo\.toml|Cargo\.lock|rust-toolchain(\.toml)?|rustfmt\.toml|\.rustfmt\.toml|clippy\.toml|\.clippy\.toml|\.cargo/config(\.toml)?)$'; then
  rustup toolchain install 1.100.0 --profile minimal --component clippy,rustfmt
  export RUSTUP_TOOLCHAIN=1.100.0
  [[ -z "${GITHUB_ENV:-}" ]] || echo 'RUSTUP_TOOLCHAIN=1.100.0' >> "$GITHUB_ENV"
fi
if contains '\.go$|(^|/)(go\.(mod|sum)|go\.work(\.sum)?|\.golangci\.(yml|yaml|toml))$'; then
  go_bin="$(go env GOPATH)/bin"
  if [[ ! -x "$go_bin/golangci-lint" ]] || ! "$go_bin/golangci-lint" version | grep -q 'version 2.8.0'; then
    go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.8.0
  fi
  export PATH="$go_bin:$PATH"
  [[ -z "${GITHUB_PATH:-}" ]] || echo "$go_bin" >> "$GITHUB_PATH"
fi
