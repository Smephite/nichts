{
  config,
  enabled,
  lib,
  ...
}: let
  inherit (config.modules.system) username;
in {
  config = lib.mkIf enabled {
    home-manager.users.${username} = {
      # read as file so that catppuccin theme can modify the string
      programs.waybar.style = builtins.readFile ./waybar.css;
    };
  };
}
