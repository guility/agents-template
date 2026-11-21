#!/usr/bin/env bash
set -euo pipefail

root="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"
manifest="$root/artifacts/images/manifest.tsv"
refs="$root/artifacts/registry-image-refs.txt"
test -s "$manifest" || { echo "Build image manifest is missing or empty" >&2; exit 1; }
printf '%s' "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin
mkdir -p "$(dirname "$refs")"
: > "$refs"
while IFS=$'\t' read -r name production_tag production_id tests_tag tests_id; do
  docker load -i "$root/artifacts/images/$name-production.tar"
  actual="$(docker image inspect --format='{{.Id}}' "$production_tag")"
  [[ "$actual" == "$production_id" ]] || { echo "Production image ID changed after build" >&2; exit 1; }
  output="$(docker push "$production_tag")"
  digest="$(printf '%s\n' "$output" | sed -n 's/.*digest: \(sha256:[0-9a-f]*\).*/\1/p' | tail -1)"
  test -n "$digest" || { echo "Registry did not return a digest for $production_tag" >&2; exit 1; }
  printf '%s@%s\n' "$production_tag" "$digest" >> "$refs"
done < "$manifest"
