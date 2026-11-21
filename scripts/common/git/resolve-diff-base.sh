#!/usr/bin/env bash
set -euo pipefail

head="${1:-HEAD}"
explicit="${2:-}"
remote="${3:-origin}"
default_branch="${4:-${CI_DEFAULT_BRANCH:-main}}"

commit_ref() {
  git rev-parse --verify "$1^{commit}" 2>/dev/null
}

if [[ -n "$explicit" ]] && commit_ref "$explicit" >/dev/null; then
  commit_ref "$explicit"
  exit 0
fi

remote_ref="refs/remotes/$remote/$default_branch"
if commit_ref "$remote_ref" >/dev/null; then
  base="$(git merge-base "$head" "$remote_ref" 2>/dev/null || true)"
  if [[ -n "$base" ]]; then
    printf '%s\n' "$base"
    exit 0
  fi
fi

echo "Cannot resolve diff base: provide a valid base SHA or fetch $remote/$default_branch." >&2
exit 2
