# Shared sandbox/nix-portable setup — source this, don't execute it
# shellcheck shell=bash

USER_NAME="${USER:-$(id -un)}"

# Per-machine nix store: prefer the local /scratch*/<user> that already holds
# a store (so a deliberately placed store wins), else the first that exists,
# else try to create one. Override with NP_LOCATION for special cases.
if [[ -z "${NP_LOCATION:-}" ]]; then
  for d in /scratch /scratch1 /scratch2 /scratch3 /scratch4; do
    if [[ -d "$d/$USER_NAME/.nix-portable" ]]; then
      NP_LOCATION="$d/$USER_NAME"
      break
    fi
  done
fi
if [[ -z "${NP_LOCATION:-}" ]]; then
  for d in /scratch /scratch1 /scratch2 /scratch3 /scratch4; do
    if [[ -d "$d/$USER_NAME" ]]; then
      NP_LOCATION="$d/$USER_NAME"
      break
    fi
  done
fi
if [[ -z "${NP_LOCATION:-}" ]]; then
  for d in /scratch /scratch1 /scratch2 /scratch3 /scratch4; do
    if [[ -d "$d" ]] && mkdir -p "$d/$USER_NAME" 2>/dev/null; then
      NP_LOCATION="$d/$USER_NAME"
      break
    fi
  done
fi
if [[ -z "${NP_LOCATION:-}" ]]; then
  echo "!! no local /scratch*/$USER_NAME found or creatable — set NP_LOCATION" >&2
  return 1 2>/dev/null || exit 1
fi

NP_BIN="${NP_BIN:-$HOME/.local/bin/nix-portable}"
NIX_HOME="${HOME}/nix-home"
NP_DIR="${NP_LOCATION}/.nix-portable"

# Runtime: bwrap when unprivileged user namespaces work (near-native speed,
# real mount namespace so autofs/SEPP work), proot as ptrace-based fallback.
if [[ -z "${NP_RUNTIME:-}" ]]; then
  if unshare -U -r true 2>/dev/null; then
    NP_RUNTIME=bwrap
  else
    NP_RUNTIME=proot
  fi
fi
export NP_LOCATION NP_RUNTIME

export NIX_CONFIG="use-sqlite-wal = false
fsync-metadata = false
filter-syscalls = false
sandbox = false
fallback = true
build-users-group =
extra-substituters = https://cache.kai.run/nixos https://zed.cachix.org https://cache.numtide.com
extra-trusted-public-keys = nixos:m1C4Znb4JdZre2SJyregJz/kDU3ELalD8qEJc/dP0KE= zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="

ATTIC_TOKEN="${NIX_HOME}/.local/share/agenix/agenix/attic-pull-token"
if [[ -f "$ATTIC_TOKEN" ]]; then
  export NIX_CONFIG="$NIX_CONFIG
netrc-file = $ATTIC_TOKEN"
fi

# Per-host state: the store (and thus activation/profile paths) is
# machine-local, so cached paths must not leak across machines via NFS home.
PORTABLE_STATE="${PORTABLE_STATE:-$HOME/.local/state/nix-portable/$(hostname -s)}"
mkdir -p "$PORTABLE_STATE"
export XDG_STATE_HOME="$PORTABLE_STATE"

# Nix's eval/fetcher caches are sqlite — keep them off NFS, on local scratch.
export XDG_CACHE_HOME="${NP_LOCATION}/.cache"
mkdir -p "$XDG_CACHE_HOME"

# Common environment variables for nix programs.
# PATH: nix profile shadows SEPP shadows system (see references/personal-setup.md).
NIX_ENV_ARGS=(
  env -i
  HOME="$NIX_HOME"
  USER="$USER_NAME"
  TERM="${TERM:-xterm-256color}"
  LANG="${LANG:-C.UTF-8}"
  PATH="$NIX_HOME/.nix-profile/bin:/usr/sepp/bin:/usr/local/bin:/usr/bin:/bin"
  DISPLAY="${DISPLAY:-}"
  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}"
  XAUTHORITY="${XAUTHORITY:-${HOME}/.Xauthority}"
  DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}"
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
  SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}"
  SSH_CONNECTION="${SSH_CONNECTION:-}"
  NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
  SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
  fish_features=no-keyboard-protocols
  NIX_CONFIG="$NIX_CONFIG"
  XDG_CACHE_HOME="$XDG_CACHE_HOME"
  NP_LOCATION="$NP_LOCATION"
  NP_RUNTIME="$NP_RUNTIME"
  NP_BIN="$NP_BIN"
)

# Bind everything except /nix (bound from the store), /dev and /proc
# (mounted specially per runtime).
_top_level_dirs() {
  find / -mindepth 1 -maxdepth 1 -not -name nix -not -name dev -not -name proc 2>/dev/null
}

if [[ "$NP_RUNTIME" == "bwrap" ]]; then
  BWRAP="${BWRAP:-$(command -v bwrap 2>/dev/null || echo "$NP_DIR/bin/bwrap")}"

  # Args are built at call time: on a fresh machine $NP_DIR only exists after
  # the first $NP_BIN invocation bootstraps it.
  _sandbox_args() {
    mkdir -p "$NP_DIR/emptyroot"
    SANDBOX_ARGS=(--bind "$NP_DIR/emptyroot" / --dev-bind /dev /dev --proc /proc --bind "$NP_DIR/nix" /nix)
    for p in $(_top_level_dirs); do
      SANDBOX_ARGS+=(--bind "$p" "$p")
    done
  }

  # Run a command inside the sandbox, returning when done
  sandbox_run() {
    local SANDBOX_ARGS
    _sandbox_args
    "$BWRAP" "${SANDBOX_ARGS[@]}" -- "$@"
  }

  # Run a command inside the sandbox with clean nix env, replacing this process
  sandbox_exec() {
    local SANDBOX_ARGS
    _sandbox_args
    exec "$BWRAP" "${SANDBOX_ARGS[@]}" -- "${NIX_ENV_ARGS[@]}" "$@"
  }
else
  PROOT="${NP_DIR}/bin/proot"
  export PROOT_LUSER_ID=0
  export PROOT_NO_SECCOMP="${PROOT_NO_SECCOMP:-1}"
  NIX_ENV_ARGS+=(PROOT_LUSER_ID=0)

  _sandbox_args() {
    SANDBOX_ARGS=(-r "$NP_DIR/emptyroot" -b /dev:/dev -b /proc:/proc -b "$NP_DIR/nix:/nix")
    for p in $(_top_level_dirs); do
      SANDBOX_ARGS+=(-b "$p:$p")
    done
  }

  sandbox_run() {
    local SANDBOX_ARGS
    _sandbox_args
    "$PROOT" "${SANDBOX_ARGS[@]}" -0 "$@"
  }

  sandbox_exec() {
    local SANDBOX_ARGS
    _sandbox_args
    exec "$PROOT" "${SANDBOX_ARGS[@]}" "${NIX_ENV_ARGS[@]}" "$@"
  }
fi

# Backwards-compatible aliases
proot_run() { sandbox_run "$@"; }
proot_exec() { sandbox_exec "$@"; }
