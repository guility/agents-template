#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
manifest="$root/artifacts/images/manifest.tsv"
test -s "$manifest" || { echo "No built tests images are available for the required unit gate" >&2; exit 1; }
while IFS=$'\t' read -r name production_tag production_id tests_tag tests_id; do
  docker load -i "$root/artifacts/images/$name-tests.tar"
  actual="$(docker image inspect --format='{{.Id}}' "$tests_tag")"
  [[ "$actual" == "$tests_id" ]] || { echo "Tests image ID changed after build" >&2; exit 1; }
  report_name="${name#template-}"
  coverage="$root/artifacts/reports/coverage-image/$report_name"
  mkdir -p "$coverage/test-results" "$coverage/coverage" "$coverage/docs"
  if [[ "$name" == template-* ]]; then
    language="${name#template-}"
    docker run --rm --network none --entrypoint bash \
      -v "$coverage/test-results:/workspace/src/templates/$language/test-results" \
      -v "$coverage/coverage:/workspace/src/templates/$language/coverage" \
      -v "$coverage/docs:/workspace/src/templates/$language/docs/coverage" \
      "$tests_id" /workspace/scripts/ci/checks/test-runners/test-unit.sh
  else
    docker run --rm --network none -v "$coverage:/workspace/artifacts/reports/coverage" \
      "$tests_id" /usr/local/bin/run-unit-tests
  fi
done < "$manifest"
