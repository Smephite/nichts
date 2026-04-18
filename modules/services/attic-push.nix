{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.modules.services.attic-push;
in
{
  options.modules.services.attic-push = {
    enable = lib.mkEnableOption "attic push post-build-hook";

    cacheName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Name of the attic cache to push to.";
    };

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://cache.app.kai.run";
      description = "URL of the attic server.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.attic-push-token = {
      file = "${self}/secrets/attic-push.age";
      mode = "0400";
    };

    nix.settings.post-build-hook =
      let
        pushScript = pkgs.writeShellScript "attic-push" ''
          set -euo pipefail
          export ATTIC_TOKEN=$(cat ${config.age.secrets.attic-push-token.path})
          ${pkgs.attic-client}/bin/attic login local ${cfg.serverUrl} "$ATTIC_TOKEN" 2>/dev/null
          ${pkgs.attic-client}/bin/attic push local:${cfg.cacheName} $OUT_PATHS 2>/dev/null || true
        '';
      in
      "${pushScript}";
  };
}
