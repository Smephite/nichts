let
  keys = import ./ssh/public_keys.nix;
  masterKeys = import ./ssh/master_keys.nix;
  allKeys = import ./ssh/all_keys.nix;
  allHosts = import ./ssh/host_keys.nix;
  allUsers = import ./ssh/user_keys.nix;

  userKeySecrets = import ./ssh/_user_secrets.nix;
in
  {
    # Caddy reverse proxy secrets
    "caddy/starhaven-caddyfile.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };
    "caddy/c3-caddyfile.age" = {
      publicKeys = [keys.host-c3] ++ masterKeys;
      armor = false;
    };
    "caddy/starhaven-services.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };
    "caddy/c3-services.age" = {
      publicKeys = [keys.host-c3] ++ masterKeys;
      armor = false;
    };
    "caddy/env.age" = {
      publicKeys = [keys.host-starhaven keys.host-c3] ++ masterKeys;
      armor = false;
    };

    "telegram.age" = {
      publicKeys =
        [
          keys.host-starhaven
          keys.host-c3
        ]
        ++ masterKeys;
      armor = false;
    };
    "wg.starhaven.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };
    "wg.preshared.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };

    "nylon.central.age" = {
      publicKeys = [keys.host-starhaven keys.host-c3] ++ masterKeys;
      armor = false;
    };

    "nylon.starhaven.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };
    "nylon.c3.age" = {
      publicKeys = [keys.host-c3] ++ masterKeys;
      armor = false;
    };

    "nylon.central.key.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };

    "radicle.starhaven.age" = {
      publicKeys = [keys.host-starhaven] ++ masterKeys;
      armor = false;
    };

    "uni.vpn.age" = {
      publicKeys =
        [
          keys.host-heartofgold
          #      keys.host-silverwind
        ]
        ++ masterKeys;
      armor = false;
    };

    "github-ro.age" = {
      publicKeys = allKeys;
      armor = false;
    };

    "github-ssh.age" = {
      publicKeys = masterKeys;
      armor = false;
    };
    "gitlab-ssh.age" = {
      publicKeys = masterKeys;
      armor = false;
    };

    "attic.c3.age" = {
      publicKeys = [keys.host-c3] ++ masterKeys;
      armor = false;
    };

    "attic-pull.age" = {
      publicKeys = allKeys;
      armor = false;
    };

    "attic-push.age" = {
      publicKeys =
        [
          keys.host-heartofgold
          keys.host-silverwind
        ]
        ++ masterKeys;
      armor = false;
    };

    "attic-admin.age" = {
      publicKeys = masterKeys;
      armor = false;
    };
  }
  // userKeySecrets
