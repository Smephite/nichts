{ enabled, config, pkgs, lib, ... }: 

let
  username = config.modules.other.system.username;
  cfg = config.modules.theming.themes.catppuccin;
in
{
  #TODO: Make the accent configurable
  config = lib.mkIf enabled {
    home-manager.users.${username} = {
      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.catppuccin-cursors."${cfg.flavor}Mauve";
        name = "catppuccin-${cfg.flavor}-mauve-cursors";
        size = 22;
      };
    };
  };
}
