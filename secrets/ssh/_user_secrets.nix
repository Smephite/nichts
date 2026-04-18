let
  keys = import ./public_keys.nix;
  masterKeys = import ./master_keys.nix;
  sshUserAgeFiles = builtins.filter (name: builtins.match ".*\\.age" name != null) (
    builtins.attrNames (builtins.readDir ./user)
  );
in
builtins.listToAttrs (
  map (
    file:
    let
      hostname = builtins.replaceStrings [ ".age" ] [ "" ] file;
    in
    {
      name = "ssh/user/${file}";
      value = {
        publicKeys =
          let
            extra = builtins.filter (k: !builtins.elem k masterKeys) (
              (if keys ? "user-${hostname}" then [ keys."user-${hostname}" ] else [ ])
              ++ (if keys ? "host-${hostname}" then [ keys."host-${hostname}" ] else [ ])
            );
          in
          masterKeys ++ extra;
        armor = false;
      };
    }
  ) sshUserAgeFiles
)
