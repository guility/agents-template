#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
tool_project="$root/scripts/ci/quality-tools"
mkdir -p "$root/artifacts/reports"
uv sync --project "$tool_project" --locked --no-dev
if (($#)); then
  uv run --project "$tool_project" --no-sync dryer "$@" | tee "$root/artifacts/reports/dryer.txt"
else
  uv run --project "$tool_project" --no-sync dryer | tee "$root/artifacts/reports/dryer.txt"
fi
