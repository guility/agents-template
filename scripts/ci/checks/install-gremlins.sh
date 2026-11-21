#!/usr/bin/env bash
set -euo pipefail

version=0.6.0
install_dir="${GREMLINS_INSTALL_DIR:-${HOME}/.local/bin}"
arch="$(uname -m)"
case "$arch" in
  x86_64) asset_arch=amd64 ;;
  *) echo "Gremlins $version installer supports Linux x86_64 only" >&2; exit 2 ;;
esac
test "$(uname -s)" = Linux || { echo "Gremlins installer supports Linux only" >&2; exit 2; }
archive="gremlins_${version}_linux_${asset_arch}.tar.gz"
checksum=b02a42e47935f891c9a411d68c07e211c7082609e79c2435b67c85ee9658c538
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
url="https://github.com/go-gremlins/gremlins/releases/download/v${version}/${archive}"
curl --fail --location --silent --show-error "$url" --output "$work/$archive"
echo "$checksum  $work/$archive" | sha256sum --check --status
tar -xzf "$work/$archive" -C "$work" gremlins
mkdir -p "$install_dir"
install -m 0755 "$work/gremlins" "$install_dir/gremlins"
"$install_dir/gremlins" --version
