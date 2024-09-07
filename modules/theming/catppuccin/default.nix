{
  inputs,
  config,
  pkgs,
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
    (import ./cursor.nix {
      enabled = cfg.enable;
      inherit config lib pkgs;
    })
    ./hyprland.nix
  ];

  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      flavor = cfg.flavor;
    };
    home-manager.users.${username} = {
      catppuccin = {
        enable = true;
        flavor = cfg.flavor;
      };
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
      ];
    };
  };
  options = {
    modules.theming.themes.catppuccin = {
      flavor = lib.mkOption {
        type = with types;
            enum [ "latte" "frappe" "macchiate" "mocha" ];
        default = "mocha";
        example = "latte";
        description = "Select which catppuccin flavor to use";
      }; #TODO: add accents
    };


  };
}
