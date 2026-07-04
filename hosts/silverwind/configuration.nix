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
      allowedTCPPorts = [51820];
    };
  };
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
    };
  };

  # See ../../modules
  modules = {
    system = {
      # Enable networking
      network = {
        hostname = "silverwind";
      };

      fingerprint = {
        enable = true;
        disableOnLidClose = true;
      };
      tty.enable = true;
      udev = {
        microchip.enable = true;
      };
      desktop = {
        apps = {
          gnome-calendar.enable = true;
        };
        windowManager = "cosmic";
        internalMonitor = "framework-panel";
        monitors = {
          home.groups = ["desk-main"];
          work.groups = ["work-externals"];
        };
      };
    };
    programs = {
      librepods.enable = true;
      #firefox.enable = true;
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    #       dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # MT7922 WiFi fixes: ASPM causes chip unresponsiveness; iwd handles roaming better
  boot.extraModprobeConfig = "options mt7921e disable_aspm=1";
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = false; # NM handles IP config
  };
  networking.networkmanager.wifi.backend = "iwd";

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Enable Bluetooth support
  hardware.bluetooth.enable = true;

  # Powers up the default Bluetooth controller on boot
  hardware.bluetooth.powerOnBoot = true;

  # Optional: Adds support for specialized Bluetooth audio (A2DP, etc)
  services.blueman.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
