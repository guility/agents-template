#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
branch="${QUALITY_METRICS_BRANCH:-feature/quality-metrics}"
source_dir="$(mktemp -d)"
trap 'rm -rf "$source_dir"' EXIT
cp -a "$root/docs/quality/." "$source_dir/"
git -C "$root" fetch origin "$branch" 2>/dev/null || true
if git -C "$root" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  git -C "$root" switch --force-create "$branch" "refs/remotes/origin/$branch"
else
  git -C "$root" switch --orphan "$branch"
fi
rm -rf "$root/docs/quality"
mkdir -p "$root/docs/quality"
cp -a "$source_dir/." "$root/docs/quality/"
git -C "$root" config user.name "${QUALITY_METRICS_GIT_NAME:-CI quality metrics}"
git -C "$root" config user.email "${QUALITY_METRICS_GIT_EMAIL:-ci-quality-metrics@users.noreply.github.com}"
git -C "$root" add docs/quality
if git -C "$root" diff --cached --quiet; then
  echo "Quality metrics are unchanged."
  exit 0
fi
git -C "$root" commit -m "ci: publish latest quality metrics"
if [[ -n "${CI_JOB_TOKEN:-}" && -n "${CI_SERVER_HOST:-}" && -n "${CI_PROJECT_PATH:-}" ]]; then
  git -C "$root" push "${CI_SERVER_PROTOCOL:-https}://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "HEAD:refs/heads/$branch"
else
  git -C "$root" push origin "HEAD:refs/heads/$branch"
fi
