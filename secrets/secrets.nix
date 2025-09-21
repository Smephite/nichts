let
  keys = import ./public_keys.nix;
  masterKeys = [
    keys.heartofgold
    keys.heartofgold-nix
    keys.silverwind
    keys.silverwind-nix
    keys.yubikey
  ];
 in {
  "telegram.age" = {
    publicKeys = [ keys.starhaven ] ++ masterKeys;
    armor = false;
  };
  "wg.starhaven.age" = {
    publicKeys = [ keys.starhaven ] ++ masterKeys;
    armor = false;
  };

}