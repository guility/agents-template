#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
manifest="$root/artifacts/images/manifest.tsv"
test -s "$manifest" || { echo "No built tests images are available for the required unit gate" >&2; exit 1; }
export STORAGE_DRIVER=vfs BUILDAH_FORMAT=docker
while IFS=$'\t' read -r name production_tag production_id tests_tag tests_id; do
  archive="$root/artifacts/images/$name-tests.tar"
  buildah pull "docker-archive:$archive:$tests_tag"
  actual="$(buildah images --format '{{.ID}}' "$tests_tag")"
  [[ "$actual" == "$tests_id" ]] || { echo "Tests image ID changed after build" >&2; exit 1; }
  report_name="${name#template-}"
  coverage="$root/artifacts/reports/coverage-image/$report_name"
  mkdir -p "$coverage/test-results" "$coverage/coverage" "$coverage/docs"
  container="$(buildah from "$tests_tag")"
  if [[ "$name" == template-* ]]; then
    language="${name#template-}"
    buildah run "$container" --network none \
      --volume "$coverage/test-results:/workspace/src/templates/$language/test-results" \
      --volume "$coverage/coverage:/workspace/src/templates/$language/coverage" \
      --volume "$coverage/docs:/workspace/src/templates/$language/docs/coverage" \
      bash /workspace/scripts/ci/checks/test-runners/test-unit.sh
  else
    buildah run "$container" --network none \
      --volume "$coverage:/workspace/artifacts/reports/coverage" \
      /usr/local/bin/run-unit-tests
  fi
  buildah rm "$container"
done < "$manifest"
