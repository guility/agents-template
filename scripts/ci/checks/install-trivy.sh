#!/usr/bin/env bash
set -euo pipefail

version="${TRIVY_VERSION:-0.73.0}"
install_dir="${TRIVY_INSTALL_DIR:-${HOME}/.local/bin}"
arch="$(uname -m)"
case "$arch" in x86_64) package_arch=64bit ;; aarch64|arm64) package_arch=ARM64 ;; *) echo "Unsupported Trivy architecture: $arch" >&2; exit 2 ;; esac
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
url="https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_Linux-${package_arch}.tar.gz"
curl --fail --location --silent --show-error "$url" --output "$work/trivy.tar.gz"
tar -xzf "$work/trivy.tar.gz" -C "$work" trivy
mkdir -p "$install_dir"
install -m 0755 "$work/trivy" "$install_dir/trivy"
"$install_dir/trivy" --version
