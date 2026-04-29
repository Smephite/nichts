{inputs, ...}: let
  inherit (inputs) self home-manager;
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
    inputs.claude-desktop.nixosModules.default
    "${inputs.nixpkgs-nylon-wg}/nixos/modules/services/networking/nylon-wg.nix"
  ];
in {
  ethz = home-manager.lib.homeManagerConfiguration {
    inherit specialArgs;
    modules =
      baseModules
      ++ [
        ./ethz
      ];
  };
}
