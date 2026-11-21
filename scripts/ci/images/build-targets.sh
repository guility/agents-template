#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
output="$root/artifacts/images"
image_prefix="${CI_REGISTRY_IMAGE:-local}"
if [[ -n "${GITHUB_REPOSITORY:-}" && -z "${CI_REGISTRY_IMAGE:-}" ]]; then
  image_prefix="ghcr.io/$GITHUB_REPOSITORY"
fi
commit="${CI_COMMIT_SHA:-${GITHUB_SHA:-$(git rev-parse HEAD)}}"
mkdir -p "$output"
: > "$output/manifest.tsv"
bash "$root/scripts/setup/fetch_language_templates.sh" all

build_pair() {
  local file="$1" context="$2" name="$3"
  grep -Eiq '^FROM[[:space:]].+[[:space:]]AS[[:space:]]+production[[:space:]]*$' "$file" || { echo "$file lacks production" >&2; exit 1; }
  grep -Eiq '^FROM[[:space:]]+production[[:space:]]+AS[[:space:]]+tests[[:space:]]*$' "$file" || { echo "$file tests must inherit production" >&2; exit 1; }
  local production="$image_prefix/$name:$commit-production"
  local tests="$image_prefix/$name:$commit-tests"
  docker build --pull -f "$file" --target production -t "$production" "$context"
  local production_id
  production_id="$(docker image inspect --format='{{.Id}}' "$production")"
  docker build --pull -f "$file" --target tests -t "$tests" "$context"
  local tests_id
  tests_id="$(docker image inspect --format='{{.Id}}' "$tests")"
  docker save -o "$output/$name-production.tar" "$production"
  docker save -o "$output/$name-tests.tar" "$tests"
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$production" "$production_id" "$tests" "$tests_id" >> "$output/manifest.tsv"
}

while IFS= read -r -d '' file; do
  base="$(basename "$file")"
  name="${base#Dockerfile.}"
  name="${name%.dockerfile}"
  name="app-$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  build_pair "$file" "$root" "$name"
done < <(find "$root/deploy/Dockerfiles" -maxdepth 1 -type f \( -name 'Dockerfile*' -o -name '*.dockerfile' \) -print0 2>/dev/null)

for language in python nodejs rust go csharp; do
	package="$root/src/templates/$language"
  file="$package/deploy/Dockerfiles/Dockerfile"
  test -f "$file" || { echo "Missing $language production/tests Dockerfile" >&2; exit 1; }
  context="$(mktemp -d)"
  mkdir -p "$context/src/templates/$language" "$context/scripts/common" "$context/scripts/ci/checks/test-runners"
  cp -a "$package/." "$context/src/templates/$language/"
  cp -a "$root/scripts/common/." "$context/scripts/common/"
  cp -a "$root/scripts/ci/checks/test-runners/." "$context/scripts/ci/checks/test-runners/"
  cp "$package/.dockerignore" "$context/.dockerignore"
  build_pair "$context/src/templates/$language/deploy/Dockerfiles/Dockerfile" "$context" "template-$language"
done

[[ -s "$output/manifest.tsv" ]] || { echo "No production/test image targets were built" >&2; exit 1; }
