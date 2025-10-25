{
  lib,
  pkgs,
  config,
  ...
}: let
  username = config.modules.system.username;
in {
  security.sudo.wheelNeedsPassword = true;
  home-manager.backupFileExtension = "bak";
  networking.dhcpcd.wait = "background";
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
