{
  config,
  lib,
  pkgs,
  ...
}: {
  # Bootloader.
  # Secure boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/persist/sbctl";
  };
  time.hardwareClockInLocalTime = true; # Fix system time in dualboot

  # See ../../modules
  modules = {
    system = {
      # Enable networking
      network = {
        hostname = "heartofgold";
      };

      gpu.nvidia.enable = true;

      desktop = {
        windowManager = "cosmic";
        monitors.home.groups = ["desk-main" "desk-benq"];
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
