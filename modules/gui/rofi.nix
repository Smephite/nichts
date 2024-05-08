{ config, pkgs, lib, ... }: 

with lib;
let 
  username = config.modules.other.system.username;
  cfg = config.modules.programs.rofi;
  rofi-pkg = (
    if config.modules.other.system.wayland 
      then pkgs.rofi-wayland 
    else pkgs.rofi
  );
in
{
  options.modules.programs.rofi.enable = mkEnableOption "rofi";
  options.modules.other.system.wayland = mkOption {
      type = types.bool;
      description = "Does this system use wayland?";
      default = false;
    }; #FIXME: move this to the (hopefully then) refactored options directory

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rofi-pkg
    ];
    home-manager.users.${username} = {
      programs.rofi = {
        enable = true;
        package = rofi-pkg;
      };

    };
  };
}

