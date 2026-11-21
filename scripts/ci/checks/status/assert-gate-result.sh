#!/usr/bin/env bash
set -euo pipefail

gate_name="${1:?gate name is required}"
gate_result="${2:?gate result is required}"

if [[ "$gate_result" == success ]]; then
  exit 0
fi

echo "Required gate '$gate_name' returned '$gate_result'." >&2
exit 1
