{
  inputs,
  lib,
  pkgs,
  ...
}: {
  # partly taken from github.com/bloxx12/nichts

  nix = {
    settings = {
      extra-experimental-features = [
        "flakes" # flakes
        "nix-command" # experimental nix commands
      ];
      warn-dirty = false;
    };
  };
}
