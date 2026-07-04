let
  keys = import ./public_keys.nix;
  hasPrefix = pre: str:
    builtins.stringLength str >= builtins.stringLength pre
    && builtins.substring 0 (builtins.stringLength pre) str == pre;
  # Match `host-<name>` (the primary recipient — TPM or SSH pubkey) but not
  # `host-ssh-<name>` (the raw-SSH rollback belt / CA input).
  hostNames = builtins.filter (
    name: hasPrefix "host-" name && !(hasPrefix "host-ssh-" name)
  ) (builtins.attrNames keys);
in
  map (name: keys.${name}) hostNames
