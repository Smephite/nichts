{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../options/desktop/monitors.nix
    ../common/default.nix
  ];

  nixpkgs.config.allowUnfree = true;
  security.sudo.package = pkgs.sudo.override {withInsults = true;};
  services.logrotate.checkConfig = false;

  networking.hostName = "iso"; # Define your hostname.
  networking.hostId = "ff13dcb3";

  environment.systemPackages = with pkgs; [networkmanager]; # cli tool for managing connections

  # IMPORTANT: empty password!
  users.users.${config.modules.system.username}.password = "";

  # be nice to your ssds
  services.fstrim.enable = true;
  security.polkit.enable = true;

  modules = {
    login = {
      greetd.enable = true;
      session = "Hyprland";
    };
    other = {
      system = rec {
        hostname = "iso";
        username = "dragyx";
        gitPath = "/home/${username}/repos/nichts";
        wayland = true;
        monitors = [];
      };
      home-manager = {
        enable = true;
        enableDirenv = true;
      };
    };
    programs = {
      vesktop.enable = true;
      btop.enable = true;
      firefox.enable = true;
      rofi.enable = true;
      stylix.enable = true;
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
    services.pipewire.enable = true;

    WM = {
      waybar.enable = true;
      hyprland = {
        enable = true;
        gnome-keyring.enable = true;
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
