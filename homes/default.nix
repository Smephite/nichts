{inputs, ...}: let
  inherit (inputs) self home-manager;
  inherit (self) lib;
  system = "x86_64-linux";
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  specialArgs = {
    inherit
      pkgs-unstable
      inputs
      self
      ;
  };
  baseModules = [
    inputs.agenix.homeManagerModules.default
    ../overlay.nix
    inputs.nix-index-database.homeModules.default
    inputs.claude-desktop.homeManagerModules.default
  ];
in {
  ethz = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = specialArgs;
    modules =
      baseModules
      ++ [
        ./ethz
      ];
  };
}
