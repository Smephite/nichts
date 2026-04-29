{
  pkgs,
  hmActivation,
}:
pkgs.writeShellApplication {
  name = "enter-nix-home";
  runtimeInputs = with pkgs; [coreutils nix bash];
  text = ''
    set -euo pipefail
    NIX_HOME="''${NIX_HOME:-$HOME/nix-home}"

    # Disable SQLite WAL, metadata fsync, and syscall filtering for proot/NFS compatibility
    export NIX_CONFIG="use-sqlite-wal = false
fsync-metadata = false
filter-syscalls = false"

    mkdir -p "$NIX_HOME"

    # Activate HM on first run, or when "switch" is passed
    if [[ ! -L "$NIX_HOME/.nix-profile" ]] || [[ "''${1:-}" == "switch" ]]; then
      echo ">> activating home-manager into $NIX_HOME"
      HOME="$NIX_HOME" "${hmActivation}/activate"
    fi

    # Drop into a clean login shell rooted at nix-home
    # Prefer bash from the nix-home profile if it exists, otherwise use the one from runtimeInputs
    SHELL_BIN="$NIX_HOME/.nix-profile/bin/bash"
    if [[ ! -x "$SHELL_BIN" ]]; then
      SHELL_BIN="bash"
    fi

    exec env -i \
      HOME="$NIX_HOME" \
      USER="''${USER:-$(id -un)}" \
      TERM="''${TERM:-xterm-256color}" \
      LANG="''${LANG:-C.UTF-8}" \
      PATH="$NIX_HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin" \
      SSH_AUTH_SOCK="''${SSH_AUTH_SOCK:-}" \
      SSH_CONNECTION="''${SSH_CONNECTION:-}" \
      "$SHELL_BIN" --login
  '';
}
