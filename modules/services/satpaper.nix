{ 
  config, pkgs, lib, ...
}: 
with lib;

  #IMPORTANT: requires rust-overlay as flake input!
let  
  username = config.modules.other.system.username;
  cfg = config.modules.services.satpaper;
  /*
  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
    rustc = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
  };
  satpaper = rustPlatform.buildRustPackage rec {
    pname = "satpaper";
    version = "0.6.0";

    src = pkgs.fetchFromGitHub {
      owner = "Colonial-Dev";
      repo = "satpaper";
      rev = "b2016c63ffeafc70538fd2b02fa60d1c077fd694";
      hash = "sha256-NjHgpHsDOXuMcaDPoE6AEDVyjAMWRtoZ0fQ2uJiRwDE=";
    };
    cargoHash = "sha256-lD9KZcQ9bKnA1qdvCJfE0uJrP1lWVTlTS7PM5PKLpDA=";

    meta = {
      description = "Display near-real-time satellite imagery on your desktop.";
      homepage = "https://github.com/Colonial-Dev/satpaper";
      license = lib.licenses.mit; #TODO: add apache as well
      maintainers = [];
    };
  };
  */
  satpaper = pkgs.stdenv.mkDerivation {
    name = "satpaper";
    version = "0.6.0";
    src = pkgs.fetchurl {
      url = "https://github.com/Colonial-Dev/satpaper/releases/download/0.6.0/satpaper-x86_64-unknown-linux-musl";
      sha256 = "sha256-Z4Dc2/g7AcvLMme7dnnQgXPIrR9AImHXhqwWr2NHSNg=";
    };
    phases = ["installPhase" "patchPhase"];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/satpaper
      chmod +x $out/bin/satpaper
    '';
  };
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
        SATPAPER_SATELLITE="goes-east";
        SATPAPER_RESOLUTION_X="2560";
        SATPAPER_RESOLUTION_Y="1440";
        SATPAPER_DISK_SIZE="94";
        SATPAPER_TARGET_PATH="/home/${username}/wallpapers/";
      };
      serviceConfig = {
        ExecStart = "${satpaper}/bin/satpaper";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };

}
