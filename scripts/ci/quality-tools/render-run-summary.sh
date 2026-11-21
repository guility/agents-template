#!/usr/bin/env bash
set -euo pipefail

uv run --project scripts/ci/quality-tools --no-sync python scripts/ci/quality-tools/merge_pipeline_metrics.py \
  --sast-result "$QUALITY_RESULT" \
  --fast-result "$FAST_RESULT" \
  --lint-result "$QUALITY_RESULT" \
  --secrets-result "$FAST_RESULT"
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
