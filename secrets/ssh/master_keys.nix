let
  keys = import ./public_keys.nix;
in
(with keys; [
  #  keys.heartofgold-win
  #  keys.silverwind-win
  user-yubikey

  user-heartofgold-win
  user-silverwind-win

  user-heartofgold
  user-silverwind
])
