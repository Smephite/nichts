let
  keys = import ./public_keys.nix;
in
  builtins.attrValues keys
