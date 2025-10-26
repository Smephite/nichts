{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.programs.microchip;
  username = config.modules.system.username;
in
{
  options.modules.programs.microchip.enable = mkEnableOption "microchip";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ];

    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "microchip-usb-udev";
        destination = "/etc/udev/rules.d/70-microchip.rules";
        text = ''
          # Bind ftdi_sio driver to all input 
          ACTION=="add", ATTRS{idVendor}=="1514", ATTRS{idProduct}=="200a", \
          ATTRS{product}=="MCHP-Debug", ATTR{bInterfaceNumber}!="00", \
          RUN+="${pkgs.kmod}/bin/modprobe ftdi_sio", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo 1514 200a > /sys/bus/usb-serial/drivers/ftdi_sio/new_id'"

          # Unbind ftdi_sio driver for channel A which should be the JTAG
          SUBSYSTEM=="usb", DRIVER=="ftdi_sio", ATTR{bInterfaceNumber}=="00", \
          RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo $kernel > /sys/bus/usb/drivers/ftdi_sio/unbind'"
           
          # Helper (optional)
          KERNEL=="ttyUSB[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", \
          ATTRS{interface}=="MCHP-Debug", ATTRS{bInterfaceNumber}=="01", \
          SYMLINK+="ttyUSB-MCHPDebugSerialB" GROUP="dialout" MODE="0666"

          KERNEL=="ttyUSB[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", \
          ATTRS{interface}=="MCHP-Debug", ATTRS{bInterfaceNumber}=="02", \
          SYMLINK+="ttyUSB-MCHPDebugSerialC" GROUP="dialout" MODE="0666"

          KERNEL=="ttyUSB[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", \
          ATTRS{interface}=="MCHP-Debug", ATTRS{bInterfaceNumber}=="03", \
          SYMLINK+="ttyUSB-MCHPDebugSerialD" GROUP="dialout" MODE="0666"
        '';
      })
    ];
  };
}
