{ enabled, config, pkgs, lib, ... }: 

let
  username = modules.other.system.username;
  cfg = modules.theming.themes.catppuccin.flavor;
in
{
  home-manager.users.${username} = lib.mkIf enabled {
    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.catppuccin-cursors.${cfg.flavor}Pink;
      name = "${cfg.flavor}Pink";
      size = 22;
    };
  };
}
