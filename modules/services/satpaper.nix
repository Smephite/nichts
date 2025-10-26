{
  inputs,
  config,
  lib,
  ...
}:
with lib;
#IMPORTANT: requires rust-overlay as flake input!
let
  username = config.modules.system.username;
  cfg = config.modules.services.satpaper;

  # FIXME: make this generic!
  system = "x86_64-linux";

  satpaper = inputs.satpaper.packages.${system}.default;
in
{
  options.modules.services.satpaper = {
    enable = mkEnableOption "satpaper";
    /*
      wallpaper-command = mkOption {
        type = types.str;
        description = "Which commadn to execute when a new wallpaper is computed";
        default = "swww";
      };
      satellite = mkOption {
        description = "Which satellite to use";
        default = "goes-east";
        type = types.str;
      };
    */
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [ satpaper ];
    };

    systemd.user.services.satpaper = {
      enable = true;
      wantedBy = [ "default.target" ];
      description = "satpaper - generates wallpapers from satellite data";
      environment = {
        SATPAPER_SATELLITE = "goes-east";
        SATPAPER_RESOLUTION_X = "2560";
        SATPAPER_RESOLUTION_Y = "1440";
        SATPAPER_DISK_SIZE = "94";
        SATPAPER_TARGET_PATH = "/home/${username}/wallpapers/";
      };
      serviceConfig = {
        ExecStart = "${satpaper}/bin/satpaper";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
