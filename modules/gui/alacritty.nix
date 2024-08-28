{ config, lib, inputs, pkgs, ... }:
with lib; let
  username = config.modules.other.system.username;
  cfg = config.modules.programs.alacritty;
in {
  options.modules.programs.alacritty = {
    enable = mkEnableOption "alacritty";
    opacity = mkOption {
      description = "opacity of alacritty";
      type = types.number;
      default = 1.0;
    };
    blur = mkOption {
      description = "blur of alacritty";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.alacritty.enable = true;

      programs.alacritty.settings = {
        window = {
          blur = cfg.blur;
          opacity = cfg.opacity;
        };

      };
    };
  };
}
