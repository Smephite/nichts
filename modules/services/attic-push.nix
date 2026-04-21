{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.modules.services.attic-push;
  tokenPath = config.age.secrets.attic-push-token.path;
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

    nix.settings.post-build-hook = let
      pushScript = pkgs.writeShellScript "attic-push" ''
        set -euo pipefail
        if [ ! -r "${tokenPath}" ]; then
          echo "attic-push: token not available at ${tokenPath}, skipping push" >&2
          exit 0
        fi
        export ATTIC_TOKEN=$(cat ${tokenPath})
        ${pkgs.attic-client}/bin/attic login local ${cfg.serverUrl} "$ATTIC_TOKEN" 2>/dev/null
        ${pkgs.attic-client}/bin/attic push local:${cfg.cacheName} $OUT_PATHS 2>/dev/null || true
      '';
    in "${pushScript}";
  };
}
