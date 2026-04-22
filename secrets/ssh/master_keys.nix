let
  keys = import ./public_keys.nix;
  yubikey = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./master/yubikey.age);
in (with keys; [
  yubikey

  user-heartofgold-win
  user-silverwind-win

  user-heartofgold
  user-silverwind
])
