{
  lib,
  pkgs,
  config,
  ...
}: let
  username = config.modules.system.username;
in {
  security.sudo = {
    package = pkgs.sudo.override {withInsults = true;};
    wheelNeedsPassword = true;
  };

  networking.dhcpcd.wait = "background";
  networking.networkmanager = {
    plugins = [ pkgs.networkmanager-openconnect ];
  };

  home-manager.backupFileExtension = "bak";
  users.users.${username}.uid = 1000;

  # Services
  services.locate = {
    enable = true;
    interval = "hourly";
    package = pkgs.plocate;
  };
  services.udev.packages = [pkgs.yubikey-personalization];
  services.pcscd.enable = true;
  services.envfs.enable = true;
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Programs
  programs.gnupg.agent = {
    enable = true;
  };

  # ../../modules
  modules = {
    programs = {
      fish.enable = lib.mkDefault true;
      atuin.enable = lib.mkDefault true;
    };

    system = {
      network.enable = lib.mkDefault true;
    };

    other.home-manager = {
      enable = lib.mkDefault false;
    };
  };
}
