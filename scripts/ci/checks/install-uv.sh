#!/usr/bin/env bash
set -euo pipefail

export UV_VERSION="${UV_VERSION:-0.13.9}"
export UV_INSTALL_DIR="${UV_INSTALL_DIR:-${HOME}/.local/bin}"
curl --fail --location --silent --show-error https://astral.sh/uv/install.sh | sh
"$UV_INSTALL_DIR/uv" --version
