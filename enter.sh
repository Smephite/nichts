#!/usr/bin/env bash
set -euo pipefail

# Bootstrap wrapper for nix-portable environments (e.g. ETHZ cluster).
# Sets up NIX_CONFIG with substituters before HM has activated, so nix run
# can fetch enterNixHome from cache rather than building it.
#
# Usage: NP_LOCATION=/path/to/nix-store ./enter.sh [switch]

NP_LOCATION="${NP_LOCATION:-/usr/scratch2/pisoc3/msc25h18/nix}"

export NIX_CONFIG="use-sqlite-wal = false
fsync-metadata = false
filter-syscalls = false
sandbox = false
extra-substituters = https://zed.cachix.org https://cache.garnix.io
extra-trusted-public-keys = nixos:m1C4Znb4JdZre2SJyregJz/kDU3ELalD8qEJc/dP0KE= zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="

# After first HM activation the attic token will be available; pass it if present
ATTIC_TOKEN="${HOME}/nix-home/.local/share/agenix/agenix/attic-pull-token"
if [[ -f "$ATTIC_TOKEN" ]]; then
  export NIX_CONFIG="$NIX_CONFIG
netrc-file = $ATTIC_TOKEN"
fi

export NP_LOCATION NP_RUNTIME=proot PROOT_LUSER_ID=0
exec nix-portable nix run "$(dirname "$0")#enterNixHome" -- "$@"
