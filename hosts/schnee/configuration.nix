{ inputs, outputs, config, pkgs, profile-config, ... }:

{
  imports = [ ../../options/common/gpu/nvidia.nix ];

  networking.hostId = "aefab460";
  networking.interfaces.enp7s0.useDHCP = true;
  systemd.services.zfs-mount.enable = true;
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  environment.systemPackages = with pkgs; [ networkmanager ]; # cli tool for managing connections

  boot = {
    kernelParams = [ "nvidia-drm.modeset=1" ];
    initrd.supportedFilesystems = [ "zfs" ];
    supportedFilesystems = [ "zfs" ];
    zfs.extraPools = [ "bpool" ]; # pool for /boot
    loader.efi.efiSysMountPoint = "/boot/efis/nvme-Samsung_SSD_960_PRO_512GB_S3EWNX0K401532W-part1";

    loader.grub = {
      gfxpayloadEfi = "keep";
      gfxmodeEfi = "1280x1024";
      useOSProber = true;
    };
    
    # efiInstallAsRemovable = true; #DEPRECATED
    loader.grub.mirroredBoots = [
      # {devices = [ "/dev/disk/by-id/nvme-Samsung_SSD_960_PRO_512GB_S3EWNX0K401532W-part1"]; path = "/boot/efis/nvme-Samsung_SSD_960_PRO_512GB_S3EWNX0K401532W-part1";}
      {devices = [ "/dev/disk/by-id/ata-KINGSTON_SA400S37960G_50026B7783226E2F-part1"]; path = "/boot/efis/ata-KINGSTON_SA400S37960G_50026B7783226E2F-part1";}
    ];
  };
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.opengl.enable = true;
  # hardware.nvidia.modesetting.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # boot.kernelPackages = pkgs.linuxPackages_xanmod_stable; #  config.boot.zfs.package.latestCompatibleLinuxPackages;


  /*services.xserver.displayManager = {
    sddm.enable = true;
    sessionPackages = [  ];
  };*/

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
    modules = {
    other = {
      system = rec {
          hostname = "schnee";
          username = "dragyx";
          gitPath = "/home/${username}/repos/nichts";
          monitors = [
            {
              name = "Main";
              device = "DP-2";
              resolution = {
                x = 2560;
                y = 1440;
              };
              scale = 1.0;
              refresh_rate = 144;
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
              refresh_rate = 144;
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
              refresh_rate = 144;
              position = {
                x = -1440;
                y = 200;
              };
              transform = 1;
            }
          ];
          wayland = true;
      };
      home-manager = {
          enable = true;
          enableDirenv = true;
      };
    };
    programs = {
        vesktop.enable = false;
        btop.enable = true;
        mpv.enable = true;
        schizofox.enable = false;
        obs.enable = true;
        vivado.enable = false;
        rofi.enable = true;
        zathura.enable = true;
        i3.enable = false;
        # neovim.enable = true;
        git = {
            enable = true;
            userName = "Dragyx";
            userEmail = "66752602+Dragyx@users.noreply.github.com";
            defaultBranch = "main";
        };
        starship.enable = true;
        zsh = {
            enable = true;
            profiling = false;
        };
        neovim-old.enable = true;
        # nixvim.enable = true;
    };
    services = {
        pipewire.enable = true;
    };
    WM.hyprland.enable = true;
    WM.hyprland.gnome-keyring = true;
    

  };
  system.stateVersion = "21.11"; # Did you read the comment?
}
