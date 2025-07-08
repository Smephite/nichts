{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../common/default.nix
    ./packages.nix
  ];

  # framework specific for BIOS updates
  services.fwupd.enable = true;

  nixpkgs.config.allowUnfree = true;

  security.sudo.package = pkgs.sudo.override {withInsults = true;};

  services.logrotate.checkConfig = false;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.hardwareClockInLocalTime = true; # Fix system time in dualboot

  networking.hostName = "heartofgold"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [networkmanager]; # cli tool for managing connections

  # be nice to your ssds
  services.fstrim.enable = true;

  security.polkit.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
    # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  modules = {
    system = rec {
      network.hostname = "heartofgold";
      username = "kai";
      gitPath = "/home/${username}/repos/nichts";
      bluetooth.enable = true;

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

      # wayland = true;
    };
    other.home-manager = {
      enable = true;
      enableDirenv = true;
    };
    programs = {
      firefox.enable = true;
      git = {
        enable = true;
        userName = "Kai Berszin";
        userEmail = "mail@kaibersz.in";
        defaultBranch = "main";
      };
    };
    services = {
      pipewire.enable = true;
      # satpaper.enable = true;
    };
    WM = {
      # waybar.enable = true;
      hyprland = {
        enable = false;
        # gnome-keyring.enable = true;
      };
    };
  };

    ## TODO Move somewhere else
  services.xserver.displayManager = {
    setupCommands =
      lib.strings.concatMapStrings (
        m: ''            xrandr --output "${m.device}" \
                    --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.x}" \
                    --rate "${builtins.toString m.refresh_rate}" \
                    --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
                    --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
                    --rotate "${
            if m.transform == 0
            then "normal"
            else if m.transform == 1
            then "left"
            else if m.transform == 2
            then "inverted"
            else if m.transform == 3
            then "right"
            else "normal"
          }\n"
        ''
      )
      config.modules.system.monitors;
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
