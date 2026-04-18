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

  services.qemuGuest.enable = true;
  services.fstrim.enable = true;

  modules = {
    other.home-manager.enable = true;
  };

  networking = {
    hostName = "c3";
    useDHCP = lib.mkDefault true;
  };

  system.stateVersion = "25.05";
}
