{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
in {
  iso = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit lib inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      ../overlay.nix # todo: move this somewhere else
      ../modules
      inputs.home-manager.nixosModules.home-manager

      ./iso
      # "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      # "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    ];
  };
  flocke = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit lib inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      ../overlay.nix # todo: move this somewhere else
      ./flocke
      ../modules
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ];
  };
  schnee = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit lib inputs self;};
    modules = [
      inputs.disko.nixosModules.disko
      ../overlay.nix # TODO: move this somewhere else
      ./schnee
      ../modules
      inputs.home-manager.nixosModules.home-manager
      # inputs.agenix.nixosModules.default
    ];
  };
}
