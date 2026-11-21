#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$1" && pwd)"
shift
files=("$@") go_files=() module_changes=() package_changes=() full_modules=()
workspace_changed=0
find_module() {
  local directory="$1"
  while [[ "$directory" == "$root" || "$directory" == "$root/"* ]]; do
    if [[ -f "$directory/go.mod" ]]; then printf '%s' "$directory"; return 0; fi
    [[ "$directory" != "$root" ]] || break
    directory="$(dirname "$directory")"
  done
  return 1
}

for file in "${files[@]}"; do
  case "$file" in
    *.go) go_files+=("$file") ;;
    go.work|*/go.work|go.work.sum|*/go.work.sum) workspace_changed=1 ;;
    go.mod|*/go.mod|go.sum|*/go.sum|.golangci.yml|*/.golangci.yml|.golangci.yaml|*/.golangci.yaml|.golangci.toml|*/.golangci.toml)
      module_changes+=("$file")
      ;;
  esac
done

if (("${#go_files[@]}")); then files_to_format=("${go_files[@]}")
else mapfile -t files_to_format < <(find "$root" -name '*.go' -not -path '*/vendor/*')
fi
diff=""
if (( ${#files_to_format[@]} )); then diff="$(gofmt -d "${files_to_format[@]}")"; fi
[[ -z "$diff" ]] || { printf '%s\n' "$diff" >&2; exit 1; }
command -v golangci-lint >/dev/null || { echo "golangci-lint is required for changed Go files" >&2; exit 127; }

if ((workspace_changed)); then
  while IFS= read -r manifest; do
    module="$(dirname "$manifest")"
    full_modules+=("$module")
    package_changes+=("$module|./...")
  done < <(find "$root" -name go.mod -not -path '*/vendor/*' -print)
  (( ${#full_modules[@]} )) || { echo "go.mod not found for changed Go workspace" >&2; exit 1; }
fi

for file in "${module_changes[@]}"; do
  module="$(find_module "$(dirname "$root/$file")" || true)"
  if [[ -z "$module" ]]; then
    while IFS= read -r manifest; do
      module="$(dirname "$manifest")"
      full_modules+=("$module")
      package_changes+=("$module|./...")
    done < <(find "$root" -name go.mod -not -path '*/vendor/*' -print)
    (("${#full_modules[@]}")) || { echo "go.mod not found for $file" >&2; exit 1; }
  else
    full_modules+=("$module")
    package_changes+=("$module|./...")
  fi
done

for file in "${go_files[@]}"; do
  directory="$(dirname "$root/$file")"
  module="$(find_module "$directory")" || { echo "go.mod not found for $file" >&2; exit 1; }
  full=0
  for configured in "${full_modules[@]}"; do [[ "$configured" != "$module" ]] || full=1; done
  (("$full")) && continue
  if [[ "$directory" == "$module" ]]; then package_changes+=("$module|.")
  else package_changes+=("$module|./${directory#"$module"/}")
  fi
done

if (("${#package_changes[@]} == 0")); then
  manifest="$(find "$root" -name go.mod -not -path '*/vendor/*' -print -quit)"
  test -n "$manifest" || { echo "go.mod not found" >&2; exit 1; }
  package_changes+=("$(dirname "$manifest")|./...")
fi
while IFS='|' read -r module package; do
  (cd "$module" && golangci-lint run "$package")
done < <(printf '%s\n' "${package_changes[@]}" | sort -u)
