#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
tool_project="$root/scripts/ci/quality-tools"
uv sync --project "$tool_project" --locked --no-dev
target="${1:-.}"
target="$(cd "$target" && pwd)"
component="$(basename "$target")"
source_root="$target"
[[ -d "$target/src" ]] && source_root="$target/src"
report="$root/artifacts/reports/mutation/$component.txt"
mkdir -p "$(dirname "$report")"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$target/target}"
test_args=()
if [[ "$component" == "go" ]]; then
  # Go template tests live under tests/unit, outside the mutated source package.
  # `./...` skips that symlinked directory in Mutator's isolated worker.
  test_args=(--test-command 'go test -count=1 ./... ./tests/unit')
fi
if [[ -d "$target/node_modules" ]]; then
  export NODE_PATH="$target/node_modules${NODE_PATH:+:$NODE_PATH}"
fi
PATH="$target/.venv/bin:$target/node_modules/.bin:$PATH" \
  uv run --project "$tool_project" --no-sync mutator \
  --root "$target" --source-root "$source_root" --no-coverage --mutate-all \
  --max-workers "${MUTATOR_WORKERS:-4}" "${test_args[@]}" | tee "$report"
