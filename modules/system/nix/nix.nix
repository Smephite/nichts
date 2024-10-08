{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.lix-module.nixosModules.default
  ];
  # partly taken from github.com/bloxx12/nichts

  nix = {
    package = pkgs.lix;

    settings = {
      extra-experimental-features = [
        "flakes" # flakes
        "nix-command" # experimental nix commands
        "cgroups" # allow nix to execute builds inside cgroups
      ];
      substituters = [
        "https://helix.cachix.org" # a cache for helix
      ];
      trusted-public-keys = [
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };
}
