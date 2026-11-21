#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
threshold="${COMPLEXITY_THRESHOLD:-10}"
mode="${1:-full}"
shift || true
command -v lizard >/dev/null || { echo "Install pinned lizard before running this check" >&2; exit 127; }
files=()
if [[ "$mode" == files ]]; then
  files=("$@")
else
  mapfile -t files < <(git -C "$root" ls-files '*.py' '*.js' '*.jsx' '*.ts' '*.tsx' '*.rs' '*.go' '*.cs' '*.c' '*.cpp' '*.h')
fi
if ((${#files[@]} == 0)); then
  echo "No supported source files found."
  exit 0
fi
cd "$root"
report="$(lizard -C "$threshold" -w "${files[@]}" 2>&1 || true)"
if [[ -n "$report" ]]; then
  printf '%s\n' "$report" >&2
  echo "Cyclomatic complexity exceeds $threshold or the source could not be analyzed." >&2
  exit 1
fi
echo "All analyzed functions have CCN <= $threshold (${#files[@]} files)."
