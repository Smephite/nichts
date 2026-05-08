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
        monitors = [
          {
            name = "Dell";
            model = "DELL P2416D";
            resolution = {
              x = 2560;
              y = 1440;
            };
            scale = 1.2356;
            refresh_rate = 59.951;
            position = {
              x = 0;
              y = 365;
            };
          }
          {
            name = "Gigabyte";
            model = "M34WQ";
            resolution = {
              x = 3440;
              y = 1440;
            };
            scale = 1.1;
            refresh_rate = 59.973;
            position = {
              x = 2072;
              y = 293;
            };
          }
          {
            name = "BenQ";
            model = "BenQ GL2450";
            resolution = {
              x = 1920;
              y = 1080;
            };
            scale = 0.9267;
            refresh_rate = 60.0;
            position = {
              x = 5199;
              y = 0;
            };
            transform = 1;
          }
        ];
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
