{ inputs, ... }:
let
  inherit (inputs) self;
  inherit (self) lib;
  system = "x86_64-linux";
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  specialArgs = {
    inherit
      pkgs-unstable
      lib
      inputs
      self
      ;
  };
  baseModules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ../modules
    ../overlay.nix
    inputs.nix-index-database.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.claude-desktop.nixosModules.default
    "${inputs.nixpkgs-nylon-wg}/nixos/modules/services/networking/nylon-wg.nix"
  ];
in
{
  starhaven = lib.nixosSystem {
    inherit specialArgs;
    modules = baseModules ++ [
      ./starhaven
    ];
  };
  heartofgold = lib.nixosSystem {
    inherit specialArgs;
    modules = baseModules ++ [
      ./heartofgold
    ];
  };
  silverwind = lib.nixosSystem {
    inherit specialArgs;
    modules = baseModules ++ [
      ./silverwind
    ];
  };
}
