{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.system.udev.stm;
in {
  options.modules.system.udev.stm.enable = mkEnableOption "stm";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      stlink
      stlink-gui
    ];

    # Ships 49-stlinkv*.rules for ST-Link V1/V2/V2-1/V3 (uaccess + plugdev)
    services.udev.packages = [pkgs.stlink];
  };
}
