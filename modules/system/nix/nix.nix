{
  inputs,
  lib,
  pkgs,
  ...
}: {
  # partly taken from github.com/bloxx12/nichts

  nix = {
    package = pkgs.lix;

    registry = lib.mapAttrs (_: v: {flake = v;}) inputs;
    settings = {
      extra-experimental-features = [
        "flakes" # flakes
        "nix-command" # experimental nix commands
        "cgroups" # allow nix to execute builds inside cgroups
      ];
      substituters = [
        "https://helix.cachix.org" # a cache for helix
      ];
      warn-dirty = false;
      trusted-public-keys = [
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };
}
