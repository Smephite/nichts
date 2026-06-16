{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.ausweisapp;
in {
  options.modules.programs.ausweisapp = {
    enable = lib.mkEnableOption "AusweisApp for German eID card authentication";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ausweisapp
    ];

    networking.firewall.allowedUDPPorts = [24727];
  };
}
