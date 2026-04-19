{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.zed;
  username = config.modules.system.username;
in {
  options.modules.programs.zed = {
    enable = mkEnableOption "Zed editor configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.zed-editor];

    home-manager.users.${username} = {
      xdg.configFile."zed/settings.json" = {
        source = ./settings.json;
      };
    };
  };
}
