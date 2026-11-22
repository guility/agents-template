#!/usr/bin/env bash

image_source_label_args() {
  local image_source="${CI_PROJECT_URL:-}"
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    image_source="${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY"
  fi
  if [[ -n "$image_source" ]]; then
    printf '%s\n' --label "org.opencontainers.image.source=$image_source"
  fi
}
