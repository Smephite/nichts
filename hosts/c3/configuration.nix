{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./packages.nix
  ];

  modules = {
    other.home-manager.enable = true;
  };

  networking = {
    hostName = "c3";
    useDHCP = lib.mkDefault true;
  };

  system.stateVersion = "25.05";
}
