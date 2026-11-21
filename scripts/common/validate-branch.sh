#!/usr/bin/env bash
set -euo pipefail

branch="${1:-${GITHUB_HEAD_REF:-${CI_COMMIT_REF_NAME:-$(git branch --show-current)}}}"
repository="${GITHUB_REPOSITORY:-${CI_PROJECT_PATH:-${CI_PROJECT_NAME:-}}}"
if [[ -z "$repository" ]]; then
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  repository="${remote_url##*/}"
  repository="${repository%.git}"
fi
allow_language=0
[[ "${repository##*/}" == "agents-template-langs" ]] && allow_language=1

if [[ -z "$branch" ]]; then
  echo "Branch name is empty" >&2
  exit 2
fi

case "$branch" in
  main|dev|test) exit 0 ;;
esac

if [[ "$allow_language" == 1 ]]; then
  case "$branch" in
    python|nodejs|rust|go|csharp) exit 0 ;;
  esac
fi

if [[ "$branch" =~ ^(research|feature|fix)/[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] &&
  [[ "$branch" != */ && "$branch" != *..* && "$branch" != *//* ]] &&
  git check-ref-format --branch "$branch" >/dev/null 2>&1; then
  exit 0
fi

echo "Invalid branch '$branch'. Allowed: research/*, feature/*, fix/*, dev, test, main." >&2
if [[ "$allow_language" == 1 ]]; then
  echo "Language branch exceptions: python, nodejs, rust, go, csharp." >&2
fi
exit 2
