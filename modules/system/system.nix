{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.system;
in {
  options.modules.system = {

    server = mkEnableOption "is server";
    
    username = mkOption {
      description = "username for the admin user for this system";
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
      extraGroups = ["wheel"];
    };
  };
}
