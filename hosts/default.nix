{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
in {
  iso = lib.nixosSystem {
    system = "x86_64-linux";
    specialargs = {inherit lib inputs self;};
    modules = [
      inputs.stylix.nixosmodules.stylix
      ../overlay.nix # todo: move this somewhere else
      ../modules
      inputs.home-manager.nixosmodules.home-manager
      ./iso
    ];
  };
  flocke = lib.nixosSystem {
    system = "x86_64-linux";
    specialargs = {inherit lib inputs self;};
    modules = [
      inputs.stylix.nixosmodules.stylix
      ../overlay.nix # todo: move this somewhere else
      ./flocke
      ../modules
      inputs.home-manager.nixosmodules.home-manager
      inputs.nixos-hardware.nixosmodules.framework-13-7040-amd
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
