#!/usr/bin/env bash
set -euo pipefail

root="$1"
scope="$2"
shift 2
files=("$@")
python_files=() js_files=()
python_touched=0 node_touched=0 go_touched=0 rust_touched=0
lint_root="${QUALITY_STATUS_ROOT:-}/lint/fast"

lint_started() {
  local component="$1"
  [[ -n "${QUALITY_STATUS_ROOT:-}" ]] || return 0
  mkdir -p "$lint_root"
  printf 'failed\n' > "$lint_root/$component.status"
}

lint_passed() {
  local component="$1"
  [[ -n "${QUALITY_STATUS_ROOT:-}" ]] || return 0
  printf 'passed\n' > "$lint_root/$component.status"
}

run_required() {
  command -v "$1" >/dev/null || {
    echo "$1 is required for changed $2 files" >&2
    exit 127
  }
}

for file in "${files[@]}"; do
  case "$file" in
    *.py) python_files+=("$file"); python_touched=1 ;;
    pyproject.toml|*/pyproject.toml|uv.lock|*/uv.lock|ruff.toml|*/ruff.toml|.ruff.toml|*/.ruff.toml) python_touched=1 ;;
    *.js|*.jsx|*.ts|*.tsx) js_files+=("$file"); node_touched=1 ;;
    package.json|*/package.json|package-lock.json|*/package-lock.json|pnpm-lock.yaml|*/pnpm-lock.yaml|.prettierrc|*/.prettierrc|.prettierrc.*|*/.prettierrc.*|prettier.config.*|*/prettier.config.*|.editorconfig|*/.editorconfig|.prettierignore|*/.prettierignore) node_touched=1 ;;
    *.go|go.mod|*/go.mod|go.sum|*/go.sum|go.work|*/go.work|go.work.sum|*/go.work.sum|.golangci.yml|*/.golangci.yml|.golangci.yaml|*/.golangci.yaml|.golangci.toml|*/.golangci.toml) go_touched=1 ;;
    *.rs|Cargo.toml|*/Cargo.toml|Cargo.lock|*/Cargo.lock|rust-toolchain|*/rust-toolchain|rust-toolchain.toml|*/rust-toolchain.toml|rustfmt.toml|*/rustfmt.toml|.rustfmt.toml|*/.rustfmt.toml|clippy.toml|*/clippy.toml|.clippy.toml|*/.clippy.toml|.cargo/config|.cargo/config.toml|*/.cargo/config|*/.cargo/config.toml) rust_touched=1 ;;
  esac
done

if [[ ( "$scope" == all || "$scope" == python ) && "$python_touched" == 1 ]]; then
  run_required ruff Python
  lint_started python
  if (("${#python_files[@]}")); then
    ruff check "${python_files[@]}" && ruff format --check "${python_files[@]}"
  else
    ruff check "$root" && ruff format --check "$root"
  fi
  lint_passed python
fi
if [[ ( "$scope" == all || "$scope" == nodejs ) && "$node_touched" == 1 ]]; then
  run_required prettier JavaScript/TypeScript
  lint_started nodejs
  if (("${#js_files[@]}")); then prettier --check "${js_files[@]}"
  else
    mapfile -d '' node_files < <(find "$root" -type f \
      \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) \
      -not -path '*/node_modules/*' -not -path '*/.git/*' -print0)
    (("${#node_files[@]}")) && prettier --check "${node_files[@]}"
  fi
  lint_passed nodejs
fi
if [[ ( "$scope" == all || "$scope" == rust ) && "$rust_touched" == 1 ]]; then
  run_required cargo Rust
  lint_started rust
  bash "$root/scripts/ci/checks/language/run-rust-fast-checks.sh" "$root" "${files[@]}"
  lint_passed rust
fi
if [[ ( "$scope" == all || "$scope" == go ) && "$go_touched" == 1 ]]; then
  run_required gofmt Go
  lint_started go
  bash "$root/scripts/ci/checks/language/run-go-fast-checks.sh" "$root" "${files[@]}"
  lint_passed go
fi
