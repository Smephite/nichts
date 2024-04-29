{ inputs, ... }:
let 
  inherit (inputs) self;
  inherit (self) lib;
in {
  flocke = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit lib inputs self; };
    modules = [
        ../overlay.nix # TODO: move this somewhere else
        ./flocke
        ../modules
        inputs.home-manager.nixosModules.home-manager
        inputs.agenix.nixosModules.default
    ];
  };
}
