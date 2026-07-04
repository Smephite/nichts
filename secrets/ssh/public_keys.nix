let
  sshDir = ./.;
  hostDir = sshDir + "/host";
  userDir = sshDir + "/user";

  readTrim = path: builtins.replaceStrings ["\n"] [""] (builtins.readFile path);
  hasPrefix = pre: str:
    builtins.stringLength str >= builtins.stringLength pre
    && builtins.substring 0 (builtins.stringLength pre) str == pre;
  concatMap = f: list: builtins.concatLists (map f list);
  unique = list:
    builtins.attrNames (builtins.listToAttrs (map (n: {
      name = n;
      value = null;
    })
    list));

  # Extract the base name of a `<base>.pub` or `<base>.age` filename, or null.
  extractBase = name: let
    m = builtins.match "(.+)\\.(pub|age)" name;
  in
    if m == null
    then null
    else builtins.head m;

  hostFileNames = builtins.attrNames (builtins.readDir hostDir);
  hostBaseNames = unique (
    builtins.filter (b: b != null) (map extractBase hostFileNames)
  );

  # For each host, `host-<base>` prefers the `.age` file (a TPM/plugin
  # recipient string, e.g. age1tpm1...) and falls back to the raw SSH pubkey.
  # `host-ssh-<base>` is always the SSH pubkey when present — used for the
  # CA-signing / known_hosts flows and as a rollback belt during migration.
  hostKeyEntries = concatMap (
    base: let
      pubPath = hostDir + "/${base}.pub";
      agePath = hostDir + "/${base}.age";
      hasPub = builtins.pathExists pubPath;
      hasAge = builtins.pathExists agePath;
    in
      (
        if hasAge
        then [
          {
            name = "host-${base}";
            value = readTrim agePath;
          }
        ]
        else if hasPub
        then [
          {
            name = "host-${base}";
            value = readTrim pubPath;
          }
        ]
        else []
      )
      ++ (
        if hasPub
        then [
          {
            name = "host-ssh-${base}";
            value = readTrim pubPath;
          }
        ]
        else []
      )
  ) (builtins.filter (n: !(hasPrefix "." n)) hostBaseNames);

  hostKeys = builtins.listToAttrs hostKeyEntries;

  pubUserKeyFileNames = builtins.filter (name: builtins.match ".+\\.pub" name != null) (
    builtins.attrNames (builtins.readDir userDir)
  );
  # For user files we only look at `.pub`, so extracting the base is a
  # direct match — no `.age` collision to worry about.
  userBase = name: builtins.head (builtins.match "(.+)\\.pub" name);
  userKeys = builtins.listToAttrs (
    map (file: {
      name = "user-" + (userBase file);
      value = readTrim (userDir + "/${file}");
    })
    pubUserKeyFileNames
  );
in
  hostKeys // userKeys
