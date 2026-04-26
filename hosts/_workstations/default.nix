{inputs, ...}: {
  imports = [
    ../_common/default.nix
    ./configuration.nix
    ./packages.nix
  ];

  nixpkgs.overlays = [
    inputs.nichts-unfree.overlays.default
  ];
}
