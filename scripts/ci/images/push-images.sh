#!/usr/bin/env bash
set -euo pipefail

root="${CI_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
manifest="$root/artifacts/images/manifest.tsv"
refs="$root/artifacts/registry-image-refs.txt"
test -f "$manifest" || { echo "Build image manifest is missing" >&2; exit 1; }
if [[ ! -s "$manifest" ]]; then
  echo "No production images to publish; result is n/a."
  exit 0
fi
: > "$refs"
if command -v buildah >/dev/null; then
  printf '%s\n' "$CI_REGISTRY_PASSWORD" | buildah login "$CI_REGISTRY" \
    --username "$CI_REGISTRY_USER" --password-stdin
else
  printf '%s\n' "$CI_REGISTRY_PASSWORD" | docker login "$CI_REGISTRY" \
    --username "$CI_REGISTRY_USER" --password-stdin
fi

while IFS=$'\t' read -r name production_tag production_id tests_tag tests_id; do
  if command -v buildah >/dev/null; then
    buildah pull "docker-archive:$root/artifacts/images/$name-production.tar:$production_tag"
    digest_file="$root/artifacts/images/$name.digest"
    buildah push --digestfile "$digest_file" "$production_tag" "docker://$production_tag"
    digest="$(cat "$digest_file")"
  else
    docker load --input "$root/artifacts/images/$name-production.tar"
    output="$(docker push "$production_tag")"
    digest="$(printf '%s\n' "$output" | sed -n 's/.*digest: \(sha256:[0-9a-f]*\).*/\1/p' | tail -1)"
  fi
  test -n "$digest" || { echo "Registry did not return a digest for $production_tag" >&2; exit 1; }
  printf '%s/%s@%s\n' "$CI_REGISTRY_IMAGE" "$name" "$digest" >> "$refs"
done < "$manifest"
