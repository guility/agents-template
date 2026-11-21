#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
branch="${1:-${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-${CI_COMMIT_REF_NAME:-$(git branch --show-current)}}}}"
base="${2:-${CI_COMMIT_BEFORE_SHA:-${GITHUB_EVENT_BEFORE:-}}}"
head="${3:-${CI_COMMIT_SHA:-${GITHUB_SHA:-HEAD}}}"
scope="${4:-${FAST_CHECK_SCOPE:-all}}"
cd "$root"

case "$scope" in
  all|universal|python|nodejs|rust|go) ;;
  *) echo "Unsupported fast-check scope: $scope" >&2; exit 2 ;;
esac

bash scripts/common/validate-branch.sh "$branch"
base="$(bash "$root/scripts/common/git/resolve-diff-base.sh" "$head" "$base" "${REMOTE_NAME:-origin}")"

mapfile -d '' files < <(git diff --name-only --diff-filter=ACMR -z "$base" "$head")
if ((${#files[@]} == 0)); then
  echo "No outgoing changed files. Fast checks passed."
  exit 0
fi

if [[ "$scope" == all || "$scope" == universal ]]; then
  command -v gitleaks >/dev/null || { echo "gitleaks is required; install pinned fast-check tools" >&2; exit 127; }
  gitleaks git --redact --no-banner --log-opts="$base..$head" "$root"

  code=()
  for file in "${files[@]}"; do
    case "$file" in
      *.py|*.js|*.jsx|*.ts|*.tsx|*.rs|*.go|*.cs) [[ -f "$file" ]] && code+=("$file") ;;
    esac
  done
  if ((${#code[@]})); then
    command -v lizard >/dev/null || { echo "lizard is required for changed source files" >&2; exit 127; }
    output="$(lizard -C 10 -w "${code[@]}" 2>&1 || true)"
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output" >&2
      echo "Cyclomatic complexity must stay at or below 10." >&2
      exit 1
    fi
  fi
fi

if [[ "$scope" == universal ]]; then
  echo "Universal fast checks passed for $branch ($(( ${#files[@]} )) changed files)."
  exit 0
fi

if [[ "$scope" != universal ]]; then
  bash scripts/ci/checks/run-language-fast-checks.sh "$root" "$scope" "${files[@]}"
fi
echo "Fast checks passed for $branch ($(( ${#files[@]} )) changed files)."
