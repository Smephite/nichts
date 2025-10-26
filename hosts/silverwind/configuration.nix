{
  config,
  pkgs,
  inputs,
  self,
  ...
}:
{
  imports = [
    ../common/default.nix
    ./packages.nix
    inputs.noctalia.nixosModules.default
  ];

  # framework specific for BIOS updates
  services.fwupd.enable = true;

  nixpkgs.config.allowUnfree = true;

  security.sudo.package = pkgs.sudo.override { withInsults = true; };

  services.logrotate.checkConfig = false;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.hardwareClockInLocalTime = true; # Fix system time in dualboot

  networking.hostName = "silverwind"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager = {
    plugins = [ pkgs.networkmanager-openconnect ];
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    networkmanager # cli tool for managing connections
    fprintd # Fingerprint sensor
  ];

  services.fprintd.enable = true;
  #services.fprintd.tod.enable = true;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  # be nice to your ssds
  services.fstrim.enable = true;

  security.polkit.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  #services.displayManager.cosmic.enable = true;
  #services.displayManager.cosmic-greeter.enable = true;

  services.desktopManager.gnome.enable = true;
  services.desktopManager.cosmic.enable = true;
  programs.niri.enable = true;

  services.noctalia-shell.enable = true;

  services.tailscale.enable = true;

  services.nylon-wg = {
    enable = true;
    centralConfig = (self + "/secrets/central.yaml");
    node = {
      key = (self + "/secrets/priv.txt");
      id = "silverwind.core.kai.run";
    };
  };

  # COSMIC Desktop Environment
  #services.desktopManager.cosmic.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  modules = {
    system = rec {
      network.hostname = "silverwind";
      username = "kai";
      gitPath = "/home/${username}/repos/nichts";
      bluetooth.enable = true;
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
      microchip.enable = true;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
