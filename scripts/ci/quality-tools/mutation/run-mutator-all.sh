#!/usr/bin/env bash
set -euo pipefail

for language in python nodejs rust go; do
  bash scripts/ci/quality-tools/mutation/run-mutator.sh "src/templates/$language"
  report="artifacts/reports/mutation/$language/.metrics/mutate"
  mkdir -p "$report"
  cp -a "src/templates/$language/.metrics/mutate/." "$report/"
done
