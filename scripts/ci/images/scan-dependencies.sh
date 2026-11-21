#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
report_dir="$root/artifacts/reports/dependencies"
mkdir -p "$report_dir"
: > "$report_dir/counts.tsv"
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
  count="$(python3 - "$report" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
print(sum(len(result.get("Vulnerabilities") or []) for result in data.get("Results", [])))
PY
)"
  printf '%s\t%s\n' "$component" "$count" >> "$report_dir/counts.tsv"
  if ((count > 0)); then
    echo "$component has $count HIGH/CRITICAL dependency vulnerabilities" >&2
    failed=1
  fi
done
exit "$failed"
