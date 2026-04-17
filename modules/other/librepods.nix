{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.librepods;
  username = config.modules.system.username;
in {
  options.modules.programs.librepods.enable = mkEnableOption "librepods";

  config = mkIf cfg.enable {

    programs.librepods = {
      enable = true;
    };

    users.users.${username} = {
      extraGroups = ["librepods"];
    };
  };
}
