{inputs, ...}: let
  inherit (inputs) self;
  inherit (self) lib;
  system = "x86_64-linux";
  specialArgs = {inherit lib inputs self;};
  baseModules = [
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
}