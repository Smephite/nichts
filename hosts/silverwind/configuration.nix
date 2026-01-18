{
  config,
  lib,
  pkgs,
  ...
}: {

  # TODO: Fix for real
  nixpkgs.config.permittedInsecurePackages = [
                "gradle-7.6.6"
              ];

  # framework specific for BIOS updates
  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.hardwareClockInLocalTime = true; # Fix system time in dualboot
   networking = {
      firewall = {
        allowedTCPPorts = [ 51820 ];
      };
    };
  # Fingerprint
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      };
    fprintd.enable = true;
    };

  # See ../../modules
  modules = {
    system = {
      # Enable networking
      network = {
        hostname = "silverwind";
      };

      tty.enable = true;
      udev = {
        microchip.enable = true;
      };
      desktop = {
        windowManager = "kde";
        monitors = [];
      };
    };
    programs = {
      librepods.enable = true;
      #firefox.enable = true;
    };

  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
