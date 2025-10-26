{
  config,
  lib,
  pkgs,
  ...
}: {
  # framework specific for BIOS updates
  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.hardwareClockInLocalTime = true; # Fix system time in dualboot

  # be nice to your ssds
  services.fstrim.enable = true;
  # Fingerprint
  services.fprintd.enable = true;
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  age.identityPaths = ["/home/${config.modules.system.username}/.ssh/id_ed25519"];

  # See ../../modules
  modules = {
    system = {
      # Enable networking
      network = {
        hostname = "silverwind";
      };

      udev = {
        microchip.enable = true;
      };
      desktop = {
        monitors = [];
      };
    };
    programs = {
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
