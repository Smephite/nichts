{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
  system = "x86_64-linux";
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  specialArgs = {inherit pkgs-unstable lib inputs self;};
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
  heartofgold = lib.nixosSystem {
    inherit system specialArgs;
    modules =
      baseModules
      ++ [
        ./heartofgold
      ];
  };
}
