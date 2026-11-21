#!/usr/bin/env bash
set -euo pipefail

if [[ -d artifacts/reports/coverage-image ]]; then
  mkdir -p artifacts/reports/coverage
  for language in python nodejs rust go csharp; do
    source="artifacts/reports/coverage-image/$language"
    target="artifacts/reports/coverage/$language"
    if [[ -d "$source" ]]; then
      mkdir -p "$target"
      cp -a "$source/." "$target/"
    fi
  done
fi

status() {
  local file="artifacts/reports/quality/$1.status"
  [[ -f "$file" ]] || { printf n/a; return; }
  case "$(cat "$file")" in
    passed|success) printf success ;;
    failed|failure) printf failed ;;
    *) printf n/a ;;
  esac
}

sast="$(status sast)"
fast="$(status fast)"
secrets=passed
for scan in fast full; do
  file="artifacts/reports/quality/secrets/$scan.status"
  if [[ ! -f "$file" ]]; then
    [[ "$secrets" == failed ]] || secrets=n/a
    continue
  fi
  case "$(cat "$file")" in
    passed|success|pass) ;;
    failed|failure|fail) secrets=failed ;;
    *) [[ "$secrets" == failed ]] || secrets=n/a ;;
  esac
done
lint=success
lint_measured=0
for file in artifacts/reports/quality/lint/{fast,slow}/*.status; do
  [[ -f "$file" ]] || continue
  lint_value="$(cat "$file")"
  case "$lint_value" in
    failed|failure|fail) lint=failed ;;
    passed|success|pass) lint_measured=$((lint_measured + 1)) ;;
  esac
done
if [[ "$lint" != failed && "$lint_measured" -eq 0 ]]; then lint=n/a; fi
for file in artifacts/reports/quality/lint/fast/*.status; do
  [[ -f "$file" ]] || continue
  [[ "$(cat "$file")" != failed ]] || fast=failed
done
lint_args=()
[[ "$sast" == n/a ]] || lint_args+=(--require-slow-lint)
uv run --project scripts/ci/quality-tools --no-sync python scripts/ci/quality-tools/merge_pipeline_metrics.py \
  --sast-result "$sast" \
  --secret-status-root artifacts/reports/quality \
  --lint-status-root artifacts/reports/quality/lint "${lint_args[@]}"
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
