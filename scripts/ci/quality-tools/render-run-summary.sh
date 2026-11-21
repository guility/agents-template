#!/usr/bin/env bash
set -euo pipefail

lint_args=()
if [[ "$QUALITY_RESULT" != skipped ]]; then
  lint_args+=(--require-slow-lint)
fi
sast_result=n/a
if [[ -f artifacts/reports/quality/sast.status ]]; then
  sast_result="$(cat artifacts/reports/quality/sast.status)"
fi
uv run --project scripts/ci/quality-tools --no-sync python scripts/ci/quality-tools/merge_pipeline_metrics.py \
  --sast-result "$sast_result" \
  --secret-status-root artifacts/reports/quality \
  --lint-status-root artifacts/reports/quality/lint \
  "${lint_args[@]}"
uv run --project scripts/ci/quality-tools --no-sync python scripts/ci/quality-tools/metrics/render_quality_matrix.py
{
  echo '## Pipeline checks'
  echo '| Gate | Result |'
  echo '|---|---|'
  echo "| Branch name | $BRANCH_RESULT |"
  echo "| Fast push checks | $FAST_RESULT |"
  echo "| SAST and source quality | $QUALITY_RESULT |"
  echo "| Build, image security and unit | $IMAGE_RESULT |"
  echo "| Post-merge language suites | $LANGUAGE_RESULT |"
  echo "| Uncle Bob Mutator | $MUTATION_RESULT |"
  echo "| Production image publication | $PUSH_RESULT |"
  echo "| Metrics publication | $PUBLISH_RESULT |"
  cat docs/quality/quality-matrix.md
} >> "$GITHUB_STEP_SUMMARY"
