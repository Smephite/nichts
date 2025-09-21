{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../common/default.nix
    ./configuration.nix
    ./packages.nix
  ];
}
