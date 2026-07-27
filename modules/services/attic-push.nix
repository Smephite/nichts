{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.modules.services.attic-push;
  tokenPath = config.age.secrets.attic-push-token.path;
  queueDir = "/var/lib/attic-push";
in {
  options.modules.services.attic-push = {
    enable = lib.mkEnableOption "attic push post-build-hook";

    cacheName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Name of the attic cache to push to.";
    };

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://cache.kai.run";
      description = "URL of the attic server.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.attic-push-token = {
      file = "${self}/secrets/attic-push.age";
      owner = config.modules.system.username;
      mode = "0400";
    };

    warnings =
      lib.optional (!builtins.pathExists "${self}/secrets/attic-push.age")
      "modules.services.attic-push: attic-push.age not found — push hook will be a no-op until the secret is available.";

    # The post-build-hook just enqueues paths and exits immediately.
    nix.settings.post-build-hook = let
      enqueueScript = pkgs.writeShellScript "attic-enqueue" ''
        set -euo pipefail
        for p in $OUT_PATHS; do
          echo "$p" >> ${queueDir}/queue
        done
      '';
    in "${enqueueScript}";

    # Background service that drains the queue and pushes to attic.
    systemd.services.attic-push = {
      description = "Attic cache push (async queue drain)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [pkgs.attic-client];

      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "attic-push";
        ExecStart = let
          pushScript = pkgs.writeShellScript "attic-push-drain" ''
            set -euo pipefail
            queue="${queueDir}/queue"

            [ -s "$queue" ] || exit 0

            if [ ! -r "${tokenPath}" ]; then
              echo "attic-push: token not available, skipping" >&2
              exit 0
            fi

            export ATTIC_TOKEN=$(cat ${tokenPath})
            attic login local ${cfg.serverUrl} "$ATTIC_TOKEN" 2>/dev/null

            # Atomically swap the queue so new paths don't get lost.
            work="${queueDir}/queue.work"
            mv "$queue" "$work"

            # Push all paths in one invocation.
            xargs attic push local:${cfg.cacheName} < "$work" || true
            rm -f "$work"
          '';
        in "${pushScript}";
      };
    };

    systemd.timers.attic-push = {
      description = "Periodically drain attic push queue";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "30s";
        AccuracySec = "5s";
      };
    };
  };
}
