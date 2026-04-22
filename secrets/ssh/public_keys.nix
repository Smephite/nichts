let
  sshDir = ./.;
  pubHostKeyFileNames = builtins.filter (name: builtins.match ".*\\.pub" name != null) (
    builtins.attrNames (builtins.readDir (sshDir + "/host"))
  );
  pubUserKeyFileNames = builtins.filter (name: builtins.match ".*\\.pub" name != null) (
    builtins.attrNames (builtins.readDir (sshDir + "/user"))
  );
  hostKeys = builtins.listToAttrs (
    map (file: {
      name = "host-" + (builtins.replaceStrings [".pub"] [""] file);
      value = builtins.replaceStrings ["\n"] [""] (builtins.readFile (sshDir + "/host/${file}"));
    })
    pubHostKeyFileNames
  );
  userKeys = builtins.listToAttrs (
    map (file: {
      name = "user-" + (builtins.replaceStrings [".pub"] [""] file);
      value = builtins.replaceStrings ["\n"] [""] (builtins.readFile (sshDir + "/user/${file}"));
    })
    pubUserKeyFileNames
  );
in
  rec {} // hostKeys // userKeys
