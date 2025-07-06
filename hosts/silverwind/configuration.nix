{
  config,
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

  networking.hostName = "silverwind"; # Define your hostname.
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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

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
  hardware.pulseaudio.enable = false;
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
        userName = "Smephite";
        userEmail = "";
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
