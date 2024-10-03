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

    settings.extra-experimental-features = [
      "flakes" # flakes
      "nix-command" # experimental nix commands
      "cgroups" # allow nix to execute builds inside cgroups
    ];
  };
}
