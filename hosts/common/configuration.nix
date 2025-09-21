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