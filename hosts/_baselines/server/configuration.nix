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

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  modules = {
    other.home-manager.enable = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
  };

  system.stateVersion = "25.05";
}
