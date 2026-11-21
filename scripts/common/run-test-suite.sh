#!/usr/bin/env bash
set -euo pipefail

suite="${1:?Usage: run-test-suite.sh unit|integration|mutation|e2e}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
found=0

for project_root in "$root"/src/templates/*; do
  [[ -d "$project_root" ]] || continue
  language="${project_root##*/}"
  case "$language" in python|nodejs|rust|go|csharp) ;; *) continue ;; esac
  [[ -z "${TEST_LANGUAGE:-}" || "$language" == "$TEST_LANGUAGE" ]] || continue
  test_dir="$project_root/tests/$suite"
  has_suite=false
  if [[ "$suite" == mutation ]]; then
    # Native mutation runners generate mutants from source, without fixtures.
    has_suite=true
  elif [[ -d "$test_dir" ]] \
    && find "$test_dir" -type f ! -name '__init__.py' ! -name '.gitkeep' -print -quit | grep -q .; then
    has_suite=true
  elif [[ "$language" == rust && -s "$project_root/tests/$suite.rs" ]]; then
    has_suite=true
  fi
  if [[ "$has_suite" != true ]]; then
    continue
  fi
  PROJECT_ROOT="$project_root" TEST_LANGUAGE="$language" TEST_SUITE="$suite" \
    bash "$root/scripts/common/run-tests.sh"
  found=$((found + 1))
done

if [[ "$found" -eq 0 ]]; then
  echo "No non-empty $suite test suite found in src/templates" >&2
  exit 1
fi
