#!/bin/sh
set -eu

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
manifest="$root/artifacts/images/manifest.tsv"
test -f "$manifest" || { echo "Image manifest is missing" >&2; exit 1; }
if [ ! -s "$manifest" ]; then
  echo "No built images to scan; result is n/a."
  exit 0
fi
command -v trivy >/dev/null || { echo "Pinned Trivy is required for image scans" >&2; exit 127; }
tab=$(printf '\t')
while IFS="$tab" read -r name production_tag production_id tests_tag tests_id; do
  for target in production tests; do
    archive="$root/artifacts/images/$name-$target.tar"
    test -s "$archive" || { echo "Missing image archive: $archive" >&2; exit 1; }
    trivy image --input "$archive" --severity HIGH,CRITICAL --exit-code 1
  done
done < "$manifest"
