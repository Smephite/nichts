{ config, lib, inputs, pkgs, ... }:
with lib; let
  username = config.modules.other.system.username;
  cfg = config.modules.programs.librewolf;
in {
    options.modules.programs.librewolf = {
      enable = mkEnableOption "librewolf";
      extensions = mkOption {
        description = "librewolf extensions (format like https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265)";
        type = types.attrs;
        default = {};
      };
    };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.librewolf= {
        enable = true;
        /*
        profiles = {
          main = {
            id = 0;
            isDefault = true;
            search.default = "DuckDuckGo";
            extensions = with pkgs.nur.repos.rycee.firefox-addons; [
              ublock-origin
              bitwarden
              darkreader
              maya-dark
            ];
            search.force = true;
          };
        };
      };
    };
}
