#!/bin/sh
set -eu

root="${CI_PROJECT_DIR:-${GITHUB_WORKSPACE:-$(pwd)}}"
refs="$root/artifacts/registry-image-refs.txt"
test -s "$refs" || { echo "Registry image digest list is missing" >&2; exit 1; }
while IFS= read -r image_ref; do
  case "$image_ref" in
    *@sha256:*) digest="${image_ref##*@sha256:}" ;;
    *) echo "Image reference is not pinned by digest: $image_ref" >&2; exit 1 ;;
  esac
  case "$digest" in
    *[!0-9a-f]*|'') echo "Invalid image digest: $image_ref" >&2; exit 1 ;;
  esac
  [ "${#digest}" -eq 64 ] || { echo "Invalid image digest: $image_ref" >&2; exit 1; }
done < "$refs"
test -n "${DEPLOY_COMMAND:-}" || { echo "Set DEPLOY_COMMAND as a protected CI variable" >&2; exit 1; }
export REGISTRY_IMAGE_REFS_FILE="$refs"
export REGISTRY_IMAGE_REFS="$(cat "$refs")"
sh -lc "$DEPLOY_COMMAND"
