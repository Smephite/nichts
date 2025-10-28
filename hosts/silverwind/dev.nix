{
  lib,
  config,
  pkgs,
  ...
}: let
  username = config.modules.system.username;
in {
  environment.systemPackages = [
    pkgs.rofi
  ];
  home-manager.users.${username} = {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
    };
  };
}
