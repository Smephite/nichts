{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
in {
  flocke = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit lib inputs self;};
    modules = [
      inputs.stylix.nixosModules.stylix
      ../overlay.nix # TODO: move this somewhere else
      ./flocke
      ../modules
      inputs.home-manager.nixosModules.home-manager
      # inputs.agenix.nixosModules.default
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ];
  };
  schnee = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit lib inputs self;};
    modules = [
      inputs.stylix.nixosModules.stylix
      ../overlay.nix # TODO: move this somewhere else
      ./schnee
      ../modules
      inputs.home-manager.nixosModules.home-manager
      # inputs.agenix.nixosModules.default
    ];
  };
}
