{
  pkgs,
  hmActivation,
}:
pkgs.writeShellApplication {
  name = "enter-nix-home";
  runtimeInputs = with pkgs; [coreutils nix];
  text = ''
    set -euo pipefail
    NIX_HOME="''${NIX_HOME:-$HOME/nix-home}"

    # Disable SQLite WAL and metadata fsync during activation to avoid issues on NFS/shared filesystems
    export NIX_CONFIG="use-sqlite-wal = false
fsync-metadata = false"

    mkdir -p "$NIX_HOME"

    # Activate HM on first run, or when "switch" is passed
    if [[ ! -L "$NIX_HOME/.nix-profile" ]] || [[ "''${1:-}" == "switch" ]]; then
      echo ">> activating home-manager into $NIX_HOME"
      HOME="$NIX_HOME" "${hmActivation}/activate"
    fi

    # Drop into a clean login shell rooted at nix-home
    exec env -i \
      HOME="$NIX_HOME" \
      USER="''${USER:-$(id -un)}" \
      TERM="''${TERM:-xterm-256color}" \
      LANG="''${LANG:-C.UTF-8}" \
      PATH="$NIX_HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin" \
      SSH_AUTH_SOCK="''${SSH_AUTH_SOCK:-}" \
      SSH_CONNECTION="''${SSH_CONNECTION:-}" \
      "$NIX_HOME/.nix-profile/bin/bash" --login
  '';
}
