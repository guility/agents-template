#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
report_dir="$root/artifacts/reports/dependencies"
mkdir -p "$report_dir"
: > "$report_dir/counts.tsv"
: > "$report_dir/fixable.tsv"
cd "$root"

bash scripts/setup/fetch_language_templates.sh all
failed=0
for component in common python nodejs rust go csharp; do
  case "$component" in
    common) path=scripts/ci/quality-tools ;;
    *) path="src/templates/$component" ;;
  esac
  report="$report_dir/$component.json"
  trivy fs --scanners vuln --severity HIGH,CRITICAL \
    --exit-code 0 --format json --output "$report" "$path"
  read -r count fixable <<< "$(python3 - "$report" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
vulnerabilities = [
    item
    for result in data.get("Results", [])
    for item in result.get("Vulnerabilities") or []
]
fixable = sum(bool(item.get("FixedVersion")) for item in vulnerabilities)
print(len(vulnerabilities), fixable)
PY
  )"
  printf '%s\t%s\n' "$component" "$count" >> "$report_dir/counts.tsv"
  printf '%s\t%s\n' "$component" "$fixable" >> "$report_dir/fixable.tsv"
  if ((fixable > 0)); then
    echo "$component has $count HIGH/CRITICAL dependency vulnerabilities; $fixable have fixes" >&2
    failed=1
  else
    echo "$component has $count HIGH/CRITICAL dependency vulnerabilities; none have fixes"
  fi
done
exit "$failed"
