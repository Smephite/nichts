#!/usr/bin/env bash
set -euo pipefail

FLAKE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
NP_LOCATION="${NP_LOCATION:-/usr/scratch/tongariro/kberszin}"
NP_BIN="${NP_BIN:-$HOME/.local/bin/nix-portable}"
NIX_HOME="${HOME}/nix-home"
NP_DIR="${NP_LOCATION}/.nix-portable"
PROOT="${NP_DIR}/bin/proot"

export NP_LOCATION NP_RUNTIME=proot PROOT_LUSER_ID=0
export PROOT_NO_SECCOMP="${PROOT_NO_SECCOMP:-1}"

export NIX_CONFIG="use-sqlite-wal = false
fsync-metadata = false
filter-syscalls = false
sandbox = false
fallback = true
extra-substituters = https://cache.kai.run/nixos https://zed.cachix.org https://cache.garnix.io
extra-trusted-public-keys = nixos:m1C4Znb4JdZre2SJyregJz/kDU3ELalD8qEJc/dP0KE= zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="

ATTIC_TOKEN="${NIX_HOME}/.local/share/agenix/agenix/attic-pull-token"
if [[ -f "$ATTIC_TOKEN" ]]; then
  export NIX_CONFIG="$NIX_CONFIG
netrc-file = $ATTIC_TOKEN"
fi

mkdir -p "$NIX_HOME"

PORTABLE_STATE="${PORTABLE_STATE:-$HOME/.local/state/nix-portable}"
mkdir -p "$PORTABLE_STATE"
export XDG_STATE_HOME="$PORTABLE_STATE"

# Build proot args matching nix-portable's own invocation:
#   - use emptyroot as the proot root
#   - bind /dev
#   - bind the full /nix from nix-portable's state
#   - bind all top-level host directories except /nix and /dev
PROOT_BINDS=()
PROOT_BINDS+=(-r "$NP_DIR/emptyroot")
PROOT_BINDS+=(-b /dev:/dev)
PROOT_BINDS+=(-b "$NP_DIR/nix:/nix")
for p in $(find / -mindepth 1 -maxdepth 1 -not -name nix -not -name dev 2>/dev/null); do
  PROOT_BINDS+=(-b "$p:$p")
done

proot_exec() {
  exec "$PROOT" "${PROOT_BINDS[@]}" "$@"
}

proot_run() {
  "$PROOT" "${PROOT_BINDS[@]}" -0 "$@"
}

CACHE_FILE="$PORTABLE_STATE/last-activation-path"
if [[ ! -L "$NIX_HOME/.nix-profile" ]] || [[ "${1:-}" == "switch" ]]; then
  if [[ -f "$CACHE_FILE" && "${1:-}" != "switch" ]]; then
    activation="$(cat "$CACHE_FILE")"
  else
    echo ">> activating home-manager into $NIX_HOME"
    activation=$("$NP_BIN" nix build --no-link --print-out-paths \
      ${NIX_SHOW_TRACE:+--show-trace} \
      "${FLAKE}#homeConfigurations.ethz.activationPackage" | tail -1)
    echo "$activation" > "$CACHE_FILE"
  fi

  HOME="$NIX_HOME" proot_run bash "${activation}/activate"
fi

# Resolve shell binary inside proot where /nix/store symlinks are valid
SHELL_BIN=$(proot_run bash -c '
  if [[ -x "'"$NIX_HOME"'/.nix-profile/bin/fish" ]]; then
    echo "'"$NIX_HOME"'/.nix-profile/bin/fish"
  elif [[ -x "'"$NIX_HOME"'/.nix-profile/bin/bash" ]]; then
    echo "'"$NIX_HOME"'/.nix-profile/bin/bash"
  else
    echo "bash"
  fi
')

proot_exec env -i \
  HOME="$NIX_HOME" \
  USER="${USER:-$(id -un)}" \
  TERM="${TERM:-xterm-256color}" \
  LANG="${LANG:-C.UTF-8}" \
  PATH="$NIX_HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin" \
  SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
  SSH_CONNECTION="${SSH_CONNECTION:-}" \
  NIX_CONFIG="$NIX_CONFIG" \
  NP_LOCATION="$NP_LOCATION" \
  NP_RUNTIME=proot \
  PROOT_LUSER_ID=0 \
  NP_BIN="$NP_BIN" \
  "$SHELL_BIN" --login
