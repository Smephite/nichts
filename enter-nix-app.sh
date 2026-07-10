#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# shellcheck source=./nix-proot-setup.sh
source "$SCRIPT_DIR/nix-proot-setup.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: enter-nix-app <program> [args...]" >&2
  exit 1
fi

sandbox_exec "$NIX_HOME/.nix-profile/bin/$1" "${@:2}"
