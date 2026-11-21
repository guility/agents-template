#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$1" && pwd)"
shift
source "$(dirname "${BASH_SOURCE[0]}")/rust-edition.sh"
manifests=() rust_files=() project_files=()
global_change=0

find_manifest() {
  local directory="$1"
  while [[ "$directory" == "$root" || "$directory" == "$root/"* ]]; do
    if [[ -f "$directory/Cargo.toml" ]]; then
      printf '%s' "$directory/Cargo.toml"
      return 0
    fi
    [[ "$directory" != "$root" ]] || break
    directory="$(dirname "$directory")"
  done
  return 1
}

is_package() { grep -q '^\[package\][[:space:]]*$' "$1"; }
is_workspace() { grep -q '^\[workspace\][[:space:]]*$' "$1"; }
add_manifest() {
  local manifest="$1" current
  for current in "${manifests[@]}"; do [[ "$current" != "$manifest" ]] || return 0; done
  manifests+=("$manifest")
}
add_all_packages() {
  local manifest
  while IFS= read -r manifest; do
    is_package "$manifest" && add_manifest "$manifest"
  done < <(find "$root" -name Cargo.toml -not -path '*/target/*' -not -path '*/.git/*' -print)
}
for file in "$@"; do
  if [[ "$file" == "$root/"* ]]; then
    relative="${file#"$root"/}"
  elif [[ "$file" != /* ]]; then
    relative="$file"
    file="$root/$file"
  else
    relative="${file#/}"
  fi
  case "$relative" in
    *.rs) rust_files+=("$file") ;;
    Cargo.toml|*/Cargo.toml|Cargo.lock|*/Cargo.lock|rust-toolchain|*/rust-toolchain|rust-toolchain.toml|*/rust-toolchain.toml|rustfmt.toml|*/rustfmt.toml|.rustfmt.toml|*/.rustfmt.toml|clippy.toml|*/clippy.toml|.clippy.toml|*/.clippy.toml|.cargo/config|.cargo/config.toml|*/.cargo/config|*/.cargo/config.toml)
      project_files+=("$file")
      [[ "$relative" != rust-toolchain && "$relative" != */rust-toolchain \
        && "$relative" != rust-toolchain.toml && "$relative" != */rust-toolchain.toml ]] || global_change=1
      ;;
  esac
done

for file in "${rust_files[@]}" "${project_files[@]}"; do
  [[ -n "$file" ]] || continue
  manifest="$(find_manifest "$(dirname "$file")" || true)"
  if [[ -z "$manifest" ]]; then
    if [[ "$file" == *.rs ]]; then
      echo "Cargo.toml not found for changed Rust source: $file" >&2
      exit 1
    fi
    global_change=1
    continue
  fi
  if ! is_package "$manifest" || is_workspace "$manifest"; then
    global_change=1
  else
    add_manifest "$manifest"
  fi
done

if ((global_change)); then
  manifests=()
  add_all_packages
fi
((${#manifests[@]})) || { echo "No Cargo package is available for changed Rust files" >&2; exit 1; }

for manifest in "${manifests[@]}"; do
  if ((${#project_files[@]})); then
    cargo fmt --manifest-path "$manifest" -- --check
  else
    selected=()
    for file in "${rust_files[@]}"; do
      file_manifest="$(find_manifest "$(dirname "$file")" || true)"
      [[ "$file_manifest" != "$manifest" ]] || selected+=("$file")
    done
    if ((${#selected[@]})); then
      rustfmt --check --edition "$(rust_edition "$manifest")" "${selected[@]}"
    fi
  fi
  cargo clippy --manifest-path "$manifest" --locked --all-targets -- -D warnings
done
