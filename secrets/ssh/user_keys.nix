let
  keys = import ./public_keys.nix;
  hostNames = builtins.filter (name: builtins.match "user-.*" name != null) (builtins.attrNames keys);
in
map (name: keys.${name}) hostNames
