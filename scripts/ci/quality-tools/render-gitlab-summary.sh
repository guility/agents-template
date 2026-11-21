#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI_PIPELINE_SOURCE:-}" == merge_request_event ]]; then
  mkdir -p artifacts/reports/coverage
  for language in python nodejs rust go csharp; do
    source="artifacts/reports/coverage-image/$language"
    [[ -d "$source" ]] && cp -a "$source" "artifacts/reports/coverage/$language"
  done
fi

status() {
  [[ -f "artifacts/reports/quality/$1.status" ]] && printf success || printf n/a
}

sast="$(status sast)"
fast="$(status fast)"
secrets="$(status secrets)"
if [[ "$secrets" != success || "$fast" != success ]]; then
  secrets=n/a
fi
lint=success
for language in python nodejs rust go csharp; do
  [[ -f "artifacts/reports/quality/lint-$language.status" ]] || lint=n/a
done
uv run --project scripts/ci/quality-tools --no-sync python scripts/ci/quality-tools/merge_pipeline_metrics.py \
  --sast-result "$sast" --fast-result "$fast" \
  --lint-result "$lint" --secrets-result "$secrets"
uv run --project scripts/ci/quality-tools --no-sync python scripts/ci/quality-tools/metrics/render_quality_matrix.py
{
  printf '\n## CI gate results\n\n| Gate | Result |\n|---|---|\n'
  printf '| Branch validation | %s |\n' "$(status branch)"
  printf '| Fast checks | %s |\n' "$fast"
  printf '| SAST | %s |\n' "$sast"
  printf '| Lint and type checks | %s |\n' "$lint"
  printf '| Secret scan | %s |\n' "$secrets"
  cat docs/quality/quality-matrix.md
} >> "$CI_JOB_SUMMARY"
