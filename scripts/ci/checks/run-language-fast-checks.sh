#!/usr/bin/env bash
set -euo pipefail

root="$1"
scope="$2"
shift 2
files=("$@")
run_required() {
  command -v "$1" >/dev/null || {
    echo "$1 is required for changed $2 files" >&2
    exit 127
  }
}

python_files=() js_files=() go_files=() rust_files=()
python_touched=0 node_touched=0 go_touched=0 rust_touched=0
for file in "${files[@]}"; do
  case "$file" in
    *.py) python_files+=("$file"); python_touched=1 ;;
    pyproject.toml|*/pyproject.toml|uv.lock|*/uv.lock) python_touched=1 ;;
    *.js|*.jsx|*.ts|*.tsx) js_files+=("$file"); node_touched=1 ;;
    package.json|*/package.json|pnpm-lock.yaml|*/pnpm-lock.yaml|package-lock.json|*/package-lock.json) node_touched=1 ;;
    *.go) go_files+=("$file"); go_touched=1 ;;
    go.mod|*/go.mod|go.sum|*/go.sum) go_touched=1 ;;
    *.rs) rust_files+=("$file"); rust_touched=1 ;;
    Cargo.toml|*/Cargo.toml|Cargo.lock|*/Cargo.lock|rust-toolchain.toml|*/rust-toolchain.toml) rust_touched=1 ;;
  esac
done

if [[ ( "$scope" == all || "$scope" == python ) && "$python_touched" == 1 ]]; then
  run_required ruff Python
  if ((${#python_files[@]})); then
    ruff check "${python_files[@]}" && ruff format --check "${python_files[@]}"
  else
    ruff check "$root" && ruff format --check "$root"
  fi
fi
if [[ ( "$scope" == all || "$scope" == nodejs ) && "$node_touched" == 1 ]]; then
  run_required prettier JavaScript/TypeScript
  if ((${#js_files[@]})); then
    prettier --check "${js_files[@]}"
  else
    mapfile -d '' node_files < <(find "$root" -type f \
      \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) \
      -not -path '*/node_modules/*' -not -path '*/.git/*' -print0)
    ((${#node_files[@]} == 0)) || prettier --check "${node_files[@]}"
  fi
fi
if [[ ( "$scope" == all || "$scope" == rust ) && "$rust_touched" == 1 ]]; then
  run_required cargo Rust
  manifest="$(find "$root" -name Cargo.toml -not -path '*/target/*' -print -quit)"
  test -n "$manifest" || { echo "Cargo.toml not found" >&2; exit 1; }
  cargo fmt --manifest-path "$manifest" -- --check
  cargo clippy --manifest-path "$manifest" --locked --all-targets -- -D warnings
fi
if [[ ( "$scope" == all || "$scope" == go ) && "$go_touched" == 1 ]]; then
  run_required gofmt Go
  if ((${#go_files[@]})); then go_files_to_check=("${go_files[@]}")
  else mapfile -t go_files_to_check < <(find "$root" -name '*.go' -not -path '*/vendor/*')
  fi
  diff="$(gofmt -d "${go_files_to_check[@]}")"
  [[ -z "$diff" ]] || { printf '%s\n' "$diff" >&2; exit 1; }
  run_required golangci-lint Go
  module="$(find "$root" -name go.mod -not -path '*/vendor/*' -print -quit)"
  test -n "$module" || { echo "go.mod not found" >&2; exit 1; }
  (cd "$(dirname "$module")" && golangci-lint run ./...)
fi
