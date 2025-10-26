{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.network.openconnect;
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.system.network.openconnect = {
    enable = mkEnableOption "openconnect";
  };
  config = mkIf cfg.enable {
    
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "modules.system.network.openconnect requires networkmanager to be enabled!";
      }
    ];

    networking.networkmanager = {
      plugins = [pkgs.networkmanager-openconnect];
    };

  };
}
