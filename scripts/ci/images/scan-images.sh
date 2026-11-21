#!/bin/sh
set -eu

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
manifest="$root/artifacts/images/manifest.tsv"
report_dir="$root/artifacts/reports/images"
mkdir -p "$report_dir"
counts="$report_dir/counts.tsv"
: > "$counts"
test -f "$manifest" || { echo "Image manifest is missing" >&2; exit 1; }
if [ ! -s "$manifest" ]; then
  echo "No built images to scan; result is n/a."
  exit 0
fi
command -v trivy >/dev/null || { echo "Pinned Trivy is required for image scans" >&2; exit 127; }
tab=$(printf '\t')
failed=0
while IFS="$tab" read -r name production_tag production_id tests_tag tests_id; do
  for target in production tests; do
    archive="$root/artifacts/images/$name-$target.tar"
    report="$report_dir/$name-$target.json"
    if [ ! -s "$archive" ]; then
      echo "Missing image archive: $archive" >&2
      failed=1
      continue
    fi
    trivy image --input "$archive" --severity HIGH,CRITICAL \
      --exit-code 0 --format json --output "$report"
    counts_for_image=$(python3 - "$report" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
vulnerabilities = [
    item
    for result in data.get("Results", [])
    for item in result.get("Vulnerabilities") or []
]
fixable = sum(bool(item.get("FixedVersion")) for item in vulnerabilities)
print(f"{len(vulnerabilities)}\t{fixable}")
PY
    )
    total=${counts_for_image%%"$tab"*}
    fixable=${counts_for_image#*"$tab"}
    printf '%s-%s\t%s\t%s\n' "$name" "$target" "$total" "$fixable" >> "$counts"
    echo "$name $target: $total HIGH/CRITICAL findings; $fixable have fixes"
    if [ "$fixable" -gt 0 ]; then
      failed=1
    fi
  done
done < "$manifest"
exit "$failed"
