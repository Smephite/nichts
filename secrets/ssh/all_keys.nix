let
  keys = import ./public_keys.nix;
  yubikey = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./master/yubikey.age);
  hasPrefix = pre: str:
    builtins.stringLength str >= builtins.stringLength pre
    && builtins.substring 0 (builtins.stringLength pre) str == pre;
  # `host-ssh-<name>` is the raw SSH pubkey exposed for CA / known_hosts
  # and rollback belts; it is not an agenix recipient in its own right.
  # The effective per-host recipient is `host-<name>`.
  primaryNames = builtins.filter (n: !(hasPrefix "host-ssh-" n)) (builtins.attrNames keys);
in
  map (n: keys.${n}) primaryNames ++ [yubikey]
