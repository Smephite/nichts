#!/usr/bin/env bash
set -euo pipefail

FLAKE="$(cd "$(dirname "$0")" && pwd)"
NP_LOCATION="${NP_LOCATION:-/usr/scratch/larain12/kberszin/nix}"
NP_BIN="${NP_BIN:-~/.local/bin/nix-portable}"
NIX_HOME="${HOME}/nix-home"

export NP_LOCATION NP_RUNTIME=proot PROOT_LUSER_ID=0

export NIX_CONFIG="use-sqlite-wal = false
fsync-metadata = false
filter-syscalls = false
sandbox = false
extra-substituters = https://cache.kai.run/nixos https://zed.cachix.org https://cache.garnix.io
extra-trusted-public-keys = nixos:m1C4Znb4JdZre2SJyregJz/kDU3ELalD8qEJc/dP0KE= zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="

ATTIC_TOKEN="${NIX_HOME}/.local/share/agenix/agenix/attic-pull-token"
if [[ -f "$ATTIC_TOKEN" ]]; then
  export NIX_CONFIG="$NIX_CONFIG
netrc-file = $ATTIC_TOKEN"
fi


# Second pass: running inside proot, nix is available
if [[ "${_NP_INNER:-}" == "1" ]]; then
  mkdir -p "$NIX_HOME"

  # ---- NEW: use a stable portable state dir + cached activation path ----
  # change this path to somewhere persistent on your host
  PORTABLE_STATE="${PORTABLE_STATE:-$HOME/.local/state/nix-portable}"
  mkdir -p "$PORTABLE_STATE"
  export XDG_STATE_HOME="$PORTABLE_STATE"

  CACHE_FILE="$PORTABLE_STATE/last-activation-path"
  if [[ ! -L "$NIX_HOME/.nix-profile" ]] || [[ "${1:-}" == "switch" ]]; then
    if [[ -f "$CACHE_FILE" && "${1:-}" != "switch" ]]; then
      activation="$(cat "$CACHE_FILE")"
    else
      echo ">> activating home-manager into $NIX_HOME"
      activation=$(nix build --no-link --print-out-paths \
        ${NIX_SHOW_TRACE:+--show-trace} \
        "${FLAKE}#homeConfigurations.ethz.activationPackage")
      echo "$activation" > "$CACHE_FILE"
    fi

    HOME="$NIX_HOME" bash "${activation}/activate"
  fi
  # ----------------------------------------------------------------------

  if [[ -x "$NIX_HOME/.nix-profile/bin/fish" ]]; then
    SHELL_BIN="$NIX_HOME/.nix-profile/bin/fish"
  elif [[ -x "$NIX_HOME/.nix-profile/bin/bash" ]]; then
    SHELL_BIN="$NIX_HOME/.nix-profile/bin/bash"
  else
    SHELL_BIN="bash"
  fi

  exec env -i \
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
fi



# First pass: enter proot via nix shell, then re-invoke this script
export _NP_INNER=1
# Ensure the portable state dir is set for the outer invocation as well so
# the nix-portable binary can reuse any preinstalled profile (avoids fetching
# `nix` on every first pass).
PORTABLE_STATE="${PORTABLE_STATE:-$HOME/.local/state/nix-portable}"
mkdir -p "$PORTABLE_STATE"
export XDG_STATE_HOME="$PORTABLE_STATE"

exec "$NP_BIN" nix-shell -p "nix" \
  --command "bash $0 $@"
