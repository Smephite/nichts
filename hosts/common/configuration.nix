{
  config,
  pkgs,
  lib,
  ...
}: let
  username = config.modules.system.username;
in {
  # Run unpatched dynamic binaries on NixOS.
  programs.nix-ld.enable = true;
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = lib.mkDefault "Europe/Zurich";
  i18n.defaultLocale = lib.mkDefault "en_GB.UTF-8";

  nixpkgs.config.allowUnfree = true;

  # See ../../modules
  modules = {
    system = {
      authorizedKeys.enable = lib.mkDefault false;
    };
    programs = {
      git = {
        enable = lib.mkDefault true;
        userName = lib.mkDefault "Kai Berszin";
        userEmail = lib.mkDefault "mail@kaibersz.in";
      };

      nh.enable = lib.mkDefault true;
    };
  };
}