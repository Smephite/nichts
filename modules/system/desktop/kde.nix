{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (inputs) plasma-manager;

  monitors = config.modules.system.desktop.monitors;
  kdeCfg = config.modules.system.desktop.kde;

  HMcfg = config.modules.other.home-manager;
  
  username = config.modules.system.username;

in {
  options.modules.system.desktop.kde = {
    enable = lib.mkEnableOption "use KDE";

    useHomeManager = lib.mkOption { 
      type = lib.types.bool;
      default = HMcfg.enable;
      description = "Whether to use HomeManager for configuring Plasma";
    };

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow GDM to run on Wayland instead of Xserver.
      '';
    };
    configureMonitors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically configure monitors.
      '';
    };
    xWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable xWayland
      '';
    };
  };
  config = lib.mkIf kdeCfg.enable {
    # TODO: Split display and desktopmanager

    environment.systemPackages = with pkgs; 
    [
      lm_sensors # required by freon 
      # KDE
#      kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
      kdePackages.kcalc # Calculator
      kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
      kdePackages.kclock # Clock app
      kdePackages.kcolorchooser # A small utility to select a color
      kdePackages.kolourpaint # Easy-to-use paint program
      kdePackages.ksystemlog # KDE SystemLog Application
      kdePackages.sddm-kcm # Configuration module for SDDM
      kdiff3 # Compares and merges 2 or 3 files or directories
      kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
      kdePackages.partitionmanager # Optional: Manage the disk devices, partitions and file systems on your computer
      # Non-KDE graphical packages
      wayland-utils # Wayland utilities
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];
    
    services = {
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = kdeCfg.wayland;

      desktopManager.plasma6 = {
        enable = true;
      };
      
      xrdp = {
        defaultWindowManager = "startplasma-x11";
        enable = true;
        openFirewall = true;
      };
      
      xserver = {
        enable = true;
        excludePackages = [pkgs.xterm];
        xkb = {
          layout = "us";
          variant = "";
        };
      };
    };

    programs.xwayland.enable = lib.mkDefault (kdeCfg.wayland && kdeCfg.xWayland);   

    home-manager = lib.mkIf kdeCfg.useHomeManager {
      sharedModules = [ plasma-manager.homeModules.plasma-manager ];
      users."${username}" = import ./config/plasma-home.nix;
    };

    assertions = [
      {
        assertion = !(HMcfg.enable == 0 && kdeCfg.useHomeManager);
        message = "KDE homemanager configuration is enabled but homemanager is not!";
      }
    ]; 
    #services.xserver.displayManager = lib.mkIf (!kdeCfg.wayland && kdeCfg.configureMonitors) {
    #  setupCommands =
    #    lib.strings.concatMapStrings (
    #      m: ''            xrandr --output "${m.device}" \
    #                            --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.x}" \
    #                            --rate "${builtins.toString m.refresh_rate}" \
    #                            --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
    #                            --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
    #                            --rotate "${
    #          if m.transform == 0
    #          then "normal"
    #          else if m.transform == 1
    #          then "left"
    #          else if m.transform == 2
    #          then "inverted"
    #          else if m.transform == 3
    #          then "right"
    #          else "normal"
    #        }\n"
    #      ''
    #    )
    #    monitors;
    #};
  };
}
