{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.docker;
in {
  options.modules.services.docker = {
    enable = mkEnableOption "docker";

    package = mkPackageOption pkgs "docker_28" {};

    dataRoot = mkOption {
      type = types.str;
      default = "/var/lib/docker";
      description = "Root directory for Docker storage.";
    };

    addUserToGroup = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add the system username to the docker group.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation.docker = {
        enable = true;
        package = cfg.package;
        daemon.settings = {
          live-restore = false;
          data-root = cfg.dataRoot;
          default-address-pools = [
            {
              base = "172.30.0.0/16";
              size = 23;
            }
          ];
        };
        storageDriver = "overlay2";
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    }

    (mkIf cfg.addUserToGroup {
      users.users.${config.modules.system.username}.extraGroups = ["docker"];
    })
  ]);
}
