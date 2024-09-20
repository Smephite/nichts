{
  config,
  lib,
  pkgs,
  ...
}: let
  username = config.modules.system.username;
  cfg = config.modules.system.bluetooth;
in {
  options.modules.system.bluetooth.enable = lib.mkEnableOption "bluetooth";

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    # Bluetooth headset media control buttons
    systemd.user.services.mpris-proxy = {
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };
}
