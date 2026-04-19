{inputs, ...}: {
  imports = [
    ../_servers
    ./configuration.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    inputs.disko.nixosModules.disko
  ];
}
