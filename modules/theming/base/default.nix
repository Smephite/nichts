{
  config,
  pkgs,
  lib,
  ...
}: let
  username = config.modules.system.username;
in {
  home-manager.users.${username} = {
    home.pointerCursor = lib.mkDefault {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 22;
    };
  };
}
