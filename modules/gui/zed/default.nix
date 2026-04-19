{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.modules.gui.zed;
  username = config.modules.system.username;
in {
  options.modules.gui.zed = {
    enable = mkEnableOption "Zed editor configuration";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      xdg.configFile."zed/settings.json" = {
        source = ./settings.json;
      };
    };
  };
}
