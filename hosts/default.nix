{ inputs, ... }:
let
  inherit (inputs) self;
  inherit (self) lib;
  system = "x86_64-linux";
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  pkgs-local = inputs.nixpkgs-local.legacyPackages.${system};
  specialArgs = {
    inherit
      pkgs-unstable
      pkgs-local
      lib
      inputs
      self
      ;
  };
  baseModules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    ../overlay.nix
    ../modules
  ];
in
{
  silverwind = lib.nixosSystem {
    inherit system specialArgs;
    modules = baseModules ++ [
      ./silverwind
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    "${inputs.nixpkgs-local}/nixos/modules/services/networking/nylon-wg.nix"
    ];
  };
  heartofgold = lib.nixosSystem {
    inherit system specialArgs;
    modules = baseModules ++ [
      ./heartofgold
    ];
  };
}
