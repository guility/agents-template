#!/usr/bin/env bash
set -euo pipefail

version="${GITLEAKS_VERSION:-8.30.1}"
install_dir="${GITLEAKS_INSTALL_DIR:-${HOME}/.local/bin}"
arch="$(uname -m)"
case "$arch" in
  x86_64) package_arch=x64; checksum=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb ;;
  aarch64|arm64) package_arch=arm64; checksum=e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080 ;;
  *) echo "Unsupported gitleaks architecture: $arch" >&2; exit 2 ;;
esac
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$install_dir"
if [[ -x "$install_dir/gitleaks" ]] && "$install_dir/gitleaks" version 2>/dev/null | grep -Fq "$version"; then
  echo "Gitleaks $version already installed"
  exit 0
fi
url="https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_linux_${package_arch}.tar.gz"
curl --fail --location --silent --show-error "$url" --output "$work/gitleaks.tar.gz"
echo "$checksum  $work/gitleaks.tar.gz" | sha256sum --check --status
tar -xzf "$work/gitleaks.tar.gz" -C "$work" gitleaks
install -m 0755 "$work/gitleaks" "$install_dir/gitleaks"
"$install_dir/gitleaks" version
