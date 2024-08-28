{ 
  config, pkgs, lib, ...
}: 
with lib;
let
  username = config.modules.other.system.username;
  cfg = config.modules.services.satpaper;
  satpaper = pkgs.rustPlatform.buildRustPackage rec {
    pname = "satpaper";
    version = "0.6.0";

    src = fetchFromGitHub {
      owner = "Colonial-Dev";
      repo = "satpaper";
      rev = "v${version}";
      hash = lib.fakeSha256;
    };
    cargoHash = lib.fakeSha;

    meta = {
      description = "Display near-real-time satellite imagery on your desktop.";
      homepage = "https://github.com/Colonial-Dev/satpaper";
      license = lib.licenses.mit; #TODO: add apache as well
      maintainers = [];
    };
  };
in
{
  options.modules.services.satpaper = {
    enable = mkEnableOption "satpaper";
    wallpaper-command = mkOption {
      type = str;
      description = "Which commadn to execute when a new wallpaper is computed";
      default = "swww";
    };
    satellite = mkOption {
      description = "Which satellite to use";     
      default = "goes-east";
      type = str;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
        home.pkgs = [ satpaper ];
    }

    systemd.user.services.satpaper = {
      enable = true;
      wantedBy = [ "default.target" ];
      description = "Generates satellite images for use as wallpaper";
      serviceConfig = {
        Environment = "SATPAPER_SATELLITE=goes-east";
        Environment = "SATPAPER_RESOLUTION_X=2560";
        Environment = "SATPAPER_RESOLUTION_Y=1440";
        Environment = "SATPAPER_DISK_SIZE=94";
        Environment = "SATPAPER_TARGET_PATH=/home/${username}";
        ExecStart = "${satpaper}/bin/satpaper";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };

}
