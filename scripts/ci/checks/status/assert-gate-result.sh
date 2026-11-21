#!/usr/bin/env bash
set -euo pipefail

gate_name="${1:?gate name is required}"
gate_result="${2:?gate result is required}"
gate_required="${3:?required flag is required}"

if [[ "$gate_result" == success ]]; then
  exit 0
fi
if [[ "$gate_result" == skipped && "$gate_required" == false ]]; then
  exit 0
fi

echo "Gate '$gate_name' returned '$gate_result' (required=$gate_required)." >&2
exit 1
