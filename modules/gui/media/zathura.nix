{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.programs.zathura;
  username = config.modules.system.username;
in
{
  options.modules.programs.zathura.enable = mkEnableOption "zathura";

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.zathura = {
        enable = true;
        extraConfig = ''
          include catppuccin-latte
        '';
        options = {
          selection-clipboard = "clipboard";
        };
      };
    };
  };
}
