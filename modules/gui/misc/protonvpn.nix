{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.protonvpn;
  username = config.modules.system.username;
in {
  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        protonvpn-gui
        networkmanagerapplet
      ];
    };
  };
}
