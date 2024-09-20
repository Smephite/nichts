{
  inputs,
  outputs,
  config,
  pkgs,
  profile-config,
  ...
}: {
  imports = [../../options/common/gpu/nvidia.nix];

  networking.hostId = "aefab460";
  networking.interfaces.enp7s0.useDHCP = true;
  systemd.services.zfs-mount.enable = true;
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  environment.systemPackages = with pkgs; [networkmanager]; # cli tool for managing connections

  boot = {
    kernelParams = ["nvidia-drm.modeset=1"];
    initrd.supportedFilesystems = ["zfs"];
    supportedFilesystems = ["zfs"];
    zfs.extraPools = ["bpool"]; # pool for /boot
    loader.efi.efiSysMountPoint = "/boot/efi";

    loader.grub = {
      gfxpayloadEfi = "keep";
      gfxmodeEfi = "1280x1024";
      useOSProber = true;
    };
  };

  services.displayManager = {
    sessionPackages = [pkgs.hyprland]; # pkgs.gnome.gnome-session.sessions ];
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  services.gnome.gnome-keyring.enable = true;
  # security.pam.services.sddm.enableGnomeKeyring = true;

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  /*
    services.xserver.displayManager = {
    sddm.enable = true;
    sessionPackages = [  ];
  };
  */

  # virtualisation.virtualbox.host.enable = true;
  # programs.hyprland.xwayland.enable = true;
  # Enable Desktop Environment
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  security.polkit.enable = true;
  # services.xserver.displayManager.sessionPackages = [ pkgs.hyprland pkgs.sway ];

  # Important for gnome to recognise the monitors.xml that is written below
  # services.xserver.displayManager.gdm.wayland = true;

  # monitor config for gdm (wayland)

  # systemd.tmpfiles.rules = [
  #   "L+ /run/gdm/.config/monitors.xml - - - - ${pkgs.writeText "gdm-monitors.xml" (builtins.readFile ./monitors.xml)}"
  # ];

  #TODO: Add to  modules.system.monitors as option
  home-manager.users."dragyx".wayland.windowManager.hyprland.settings = {
    workspace = [
      "1,monitor:DP-2,default:true"
    ];
    exec-once = [
      "xrandr --output DP-2 --primary" # make sure xwayland windows open on right monitor:
    ];
  };

  modules = {
    login = {
      greetd.enable = true;
      session = "Hyprland";
    };
    system = rec {
      hostname = "schnee";
      username = "dragyx";
      gitPath = "/home/${username}/repos/nichts";
      bluetooth.enable = true;
      monitors = [
        {
          name = "Main";
          device = "DP-2";
          resolution = {
            x = 2560;
            y = 1440;
          };
          scale = 1.0;
          refresh_rate = 143.998001;
          position = {
            x = 0;
            y = 0;
          };
        }
        {
          name = "Right";
          device = "HDMI-A-3";
          resolution = {
            x = 2560;
            y = 1440;
          };
          scale = 1.0;
          refresh_rate = 74.9999001;
          position = {
            x = 2560;
            y = 200;
          };
          transform = 3;
        }
        {
          name = "Left";
          device = "HDMI-A-2";
          resolution = {
            x = 2560;
            y = 1440;
          };
          scale = 1.0;
          refresh_rate = 74.9999001;
          position = {
            x = -1440;
            y = 200;
          };
          transform = 1;
        }
      ];
      wayland = true;
      disks = {
        auto-partition.enable = true;
        swap-size = "64G";
        main-disk = "/dev/disk/by-id/23198F92-5359-4828-9735-097E46692060";
        storage-disks = {
          "small" = "/dev/disk/by-id/AB5CDF5C-A130-43B4-95D5-54C549F0EE4B";    
          "medium" = "/dev/disk/by-id/85C78E27-7516-43FD-BC24-826E23942071";
          "large" = "/dev/disk/by-id/0xe633c355"
        };
      };
    };
    other.home-manager = {
      enable = true;
      enableDirenv = true;
    };
    programs = {
      firefox.enable = true;
      vesktop.enable = false;
      btop.enable = true;
      mpv.enable = true;
      schizofox.enable = false;
      obs.enable = true;
      vivado.enable = false;
      rofi.enable = true;
      zathura.enable = true;
      stylix.enable = true;
      i3.enable = false;
      # neovim.enable = true;
      git = {
        enable = true;
        userName = "Dragyx";
        userEmail = "66752602+Dragyx@users.noreply.github.com";
        defaultBranch = "main";
      };
      starship.enable = true;
      neovim-old.enable = true;
      # nixvim.enable = true;
    };
    services = {
      pipewire.enable = true;
    };
    WM = {
      waybar.enable = true;
      hyprland = {
        enable = true;
        gnome-keyring.enable = true;
      };
    };
  };
  system.stateVersion = "21.11"; # Did you read the comment?
}
