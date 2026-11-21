#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?source workflow run ID is required}"
[[ "$run_id" =~ ^[0-9]+$ ]] || { echo "Invalid workflow run ID" >&2; exit 1; }

run="$(gh api "repos/${GITHUB_REPOSITORY}/actions/runs/${run_id}")"
jq -e '
  .path == ".github/workflows/ci-cd.yml" and
  .head_branch == "main" and
  .event == "push" and
  .status == "completed" and
  .conclusion == "success"
' <<< "$run" >/dev/null || {
  echo "Source must be a successful Quality pipeline push on main" >&2
  exit 1
}
