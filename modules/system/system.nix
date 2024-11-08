{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.system;
in {
  options.modules.system = {
    username = mkOption {
      description = "username for this system";
      type = types.str;
    };

    gitPath = mkOption {
      description = "path to the flake directory";
      type = types.str;
    };
  };

  config = {
    users.users.${cfg.username} = {
      isNormalUser = true;
      extraGroups = ["wheel" "adbusers"];
    };
  };
}
