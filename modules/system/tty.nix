{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.system.tty;
  username = config.modules.system.username;
in {
  options.modules.system.tty.enable = mkEnableOption "serial";

  config = mkIf cfg.enable {

    users.users.${username} = {
      extraGroups = ["dialout" "tty"];
    };
  };
}
