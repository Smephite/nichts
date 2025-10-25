{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
  system = "x86_64-linux";
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  specialArgs = {inherit pkgs-unstable lib inputs self;};
  baseModules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ../modules
    ../overlay.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    "${inputs.nixpkgs-nylon-wg}/nixos/modules/services/networking/nylon-wg.nix"
  ];
in {
  starhaven = lib.nixosSystem {
    inherit system specialArgs;
    modules =
      baseModules
      ++ [
        ./starhaven
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
