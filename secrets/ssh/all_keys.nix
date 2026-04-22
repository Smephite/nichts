let
  keys = import ./public_keys.nix;
  yubikey = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./master/yubikey.age);
in
  builtins.attrValues keys ++ [yubikey]
