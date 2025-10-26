{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  username = config.modules.system.username;
  cfg = config.modules.programs.rofi;
  rofi-pkg = (if config.modules.system.wayland then pkgs.rofi-wayland else pkgs.rofi);
in
{
  options.modules.programs.rofi.enable = mkEnableOption "rofi";
  options.modules.system.wayland = mkOption {
    type = types.bool;
    description = "Does this system use wayland?";
    default = false;
  }; # FIXME: move this to the (hopefully then) refactored options directory

  config = mkIf cfg.enable {
    environment.systemPackages = [
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
