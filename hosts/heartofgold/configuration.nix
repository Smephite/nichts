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
        niri.enable = false;
        gnome.enable = false;
        kde.enable = true;
        monitors = [
          {
            name = "Gigabyte";
            device = "DP-1";
            resolution = {
              x = 3440;
              y = 1440;
            };
            scale = 1.3;
            refresh_rate = 144.0;
            position = {
              x = 0;
              y = 0;
            };
          }
          {
            name = "BenQ";
            device = "DP-2";
            resolution = {
              x = 1920;
              y = 1080;
            };
            scale = 1.0;
            refresh_rate = 60.0;
            position = {
              x = 3440;
              y = 0;
            };
            transform = 3;
          }
          {
            name = "Dell";
            device = "DP-3";
            resolution = {
              x = 2560;
              y = 1440;
            };
            scale = 1.0;
            refresh_rate = 60.0;
            position = {
              x = -2560;
              y = 0;
            };
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
