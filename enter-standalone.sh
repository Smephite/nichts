#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
FLAKE="$SCRIPT_DIR"

# shellcheck source=./nix-proot-setup.sh
source "$SCRIPT_DIR/nix-proot-setup.sh"

mkdir -p "$NIX_HOME"

HM_CONFIG="${HM_CONFIG:-kberszin}"

CACHE_FILE="$PORTABLE_STATE/last-activation-path"

# Activation is needed on explicit "switch", when no profile exists yet, or
# when the profile points into a store this machine doesn't have (stores are
# per-machine; $NIX_HOME is shared over NFS).
needs_activation() {
  [[ "${1:-}" == "switch" ]] && return 0
  [[ -L "$NIX_HOME/.nix-profile" ]] || return 0
  [[ -d "$NP_DIR/nix/store" ]] || return 0
  sandbox_run bash -c "[[ -e \"\$(readlink -f '$NIX_HOME/.nix-profile')\" ]]" || return 0
  return 1
}

if needs_activation "${1:-}"; then
  activation=""
  if [[ "${1:-}" != "switch" && -f "$CACHE_FILE" ]]; then
    activation="$(cat "$CACHE_FILE")"
    [[ -n "$activation" && -e "$NP_DIR$activation" ]] || activation=""
  fi
  if [[ -z "$activation" ]]; then
    echo ">> activating home-manager into $NIX_HOME (store: $NP_DIR, runtime: $NP_RUNTIME)"
    activation=$("$NP_BIN" nix build --no-link --print-out-paths \
      ${NIX_SHOW_TRACE:+--show-trace} \
      "${FLAKE}#homeConfigurations.${HM_CONFIG}.activationPackage" | tail -1)
    echo "$activation" > "$CACHE_FILE"
  fi

  HOME="$NIX_HOME" sandbox_run bash "${activation}/activate"
fi

# Resolve shell binary inside the sandbox where /nix/store symlinks are valid
SHELL_BIN=$(sandbox_run bash -c '
  if [[ -x "'"$NIX_HOME"'/.nix-profile/bin/fish" ]]; then
    echo "'"$NIX_HOME"'/.nix-profile/bin/fish"
  elif [[ -x "'"$NIX_HOME"'/.nix-profile/bin/bash" ]]; then
    echo "'"$NIX_HOME"'/.nix-profile/bin/bash"
  else
    echo "bash"
  fi
')

sandbox_exec "$SHELL_BIN" --login
