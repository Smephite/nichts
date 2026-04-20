{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.modules.services.autoUpdate;
  hostname = config.networking.hostName;
  username = config.modules.system.username;
  gitPath = config.modules.system.gitPath;
  masterKeys = import (self + "/secrets/ssh/master_keys.nix");

  # Build a git allowed-signers file from the master signing keys at eval time.
  # The '*' principal accepts any signer identity (email/name).
  allowedSignersFile =
    pkgs.writeText "git-allowed-signers"
    (lib.concatMapStrings (key: "* ${key}\n") masterKeys);

  # Minimal git config that points to the allowed-signers file and enables SSH signing verification.
  gitConfig = pkgs.writeText "git-auto-update-config" ''
    [gpg]
      format = ssh
    [gpg "ssh"]
      allowedSignersFile = ${allowedSignersFile}
  '';

  # Wrapper that runs a git command as the repo owner.
  # This avoids safe.directory issues since the repo is owned by the admin user, not root.
  asUser = cmd: "${pkgs.util-linux}/bin/runuser -u ${username} -- ${cmd}";

  updateScript = pkgs.writeShellScript "nixos-auto-update" ''
    set -euo pipefail

    export GIT_CONFIG_GLOBAL=${gitConfig}

    echo "auto-update: fetching origin..."
    ${asUser "${pkgs.git}/bin/git -C ${gitPath} fetch origin"}

    echo "auto-update: verifying all commit signatures..."
    UNSIGNED=$(${asUser "${pkgs.git}/bin/git -c log.showSignature=false -C ${gitPath} log --format=\"%H %G?\" origin/main"} \
      | ${pkgs.gawk}/bin/awk '$2 != "G" { print $1 }')

    if [ -n "$UNSIGNED" ]; then
      echo "auto-update: REFUSING — unsigned or untrusted commits found:" >&2
      echo "$UNSIGNED" >&2
      exit 1
    fi

    echo "auto-update: all commits verified, updating to origin/main..."
    ${asUser "${pkgs.git}/bin/git -C ${gitPath} reset --hard origin/main"}

    echo "auto-update: rebuilding NixOS (${hostname})..."
    ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake path:${gitPath}#${hostname}
  '';
in {
  options.modules.services.autoUpdate = {
    enable = lib.mkEnableOption "Periodic NixOS auto-update from git, gated on full commit-signature verification";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd OnCalendar expression controlling how often to poll for updates";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nixos-auto-update = {
      description = "NixOS auto-update from git (signature-verified)";
      # Do not restart or stop this service when its unit changes during a
      # nixos-rebuild switch — it must be allowed to finish the very rebuild
      # that triggered the unit change.
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      after = ["network-online.target"];
      wants = ["network-online.target"];
      # Put all required binaries on PATH so that git's internal ssh/ssh-keygen
      # calls work without any GIT_SSH_COMMAND / gpg.ssh.program hacks.
      path = [
        pkgs.git
        pkgs.openssh
        pkgs.gawk
        pkgs.util-linux
        config.nix.package
      ];
      environment = {
        HOME = "/root";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${updateScript}";
      };
    };

    systemd.timers.nixos-auto-update = {
      description = "Trigger nixos-auto-update periodically";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
