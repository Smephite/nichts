{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
  system = "x86_64-linux";
  specialArgs = {inherit lib inputs self;};
  baseModules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    ../overlay.nix
    ../modules
  ];
in {
  silverwind = lib.nixosSystem {
    inherit system specialArgs;
    modules =
      baseModules
      ++ [
        ./silverwind
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ];
  };
}