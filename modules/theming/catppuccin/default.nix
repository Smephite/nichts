{
  inputs,
  config,
  lib,
  ...
}:
with lib; let
  username = config.modules.other.system.username;
  cfg = config.modules.theming.themes.catppuccin;
in {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    (import ./waybar.nix {
      enabled = cfg.enable;
      inherit config lib;
    })
  ];
  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      flavor = "mocha";
    };
    home-manager.users.${username} = {
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
      ];
    };
  };
}
