{
  config,
  pkgs,
  lib,
  ...
}: let
  username = config.modules.other.system.username;
in {
  imports = [
    ../../options/common/pin-registry.nix
    ../../options/common/preserve-system.nix
    ../../options/desktop/fonts.nix
  ];

  # use zsh as default shell
  users.users.${username}.shell = pkgs.zsh;
  home-manager.backupFileExtension = "bak";
  users.defaultUserShell = pkgs.zsh;
  networking.dhcpcd.wait = "background";
  services.locate = {
    enable = true;
    interval = "hourly";
    package = pkgs.plocate;
    localuser = null;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };

  modules = {
    programs = {
      foot.enable = lib.mkDefault true;
      foot.server = lib.mkDefault true;
      nh.enable = lib.mkDefault true;
      atuin.enable = lib.mkDefault true;
    };
  };

  time.timeZone = "Europe/Zurich";
}
