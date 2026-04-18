{
  config,
  lib,
  self,
  ...
}:
with lib;
let
  cfg = config.modules.system.sshKey;
  username = config.modules.system.username;
  hostname = config.networking.hostName;
  secretName = "ssh-${hostname}";
  ageFile = self + "/secrets/ssh/user/${hostname}.age";
  ageFileExists = builtins.pathExists ageFile;

  userKeyName = "id_ed25519_nix";
  userKeyPath = "/home/${username}/.ssh/${userKeyName}";

in
{
  options.modules.system.sshKey = {
    enable = mkEnableOption "agenix-managed SSH identity key (${userKeyPath})";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      warnings =
        optional (!ageFileExists)
          "modules.system.sshKey: ${ageFile} does not exist; SSH key will not be managed by agenix on this host";

      # The host SSH key is generated at first boot before agenix runs, which
      # breaks the chicken-and-egg problem of using the user key as the identity
      # when the user key is itself an agenix secret.
      # mkOverride 900 beats mkDefault (1000) but yields to any explicit setting (100).
      age.identityPaths = mkOverride 900 [ "/etc/ssh/ssh_host_ed25519_key" ];
    }

    (mkIf ageFileExists {
      age.secrets.${secretName} = {
        file = ageFile;
        owner = username;
        mode = "0600";
        # No custom path — agenix writes to /run/agenix/${secretName}.
        # Placement and conflict detection are handled by the activation script below.
      };

      system.activationScripts.sshKeyFromSecret = {
        deps = [
          "agenix"
          "users"
          "groups"
        ];
        text = ''
          DECRYPTED="/run/agenix/${secretName}"
          USER_KEY="${userKeyPath}"

          if [ ! -f "$DECRYPTED" ]; then
            echo "sshKeyFromSecret: $DECRYPTED not found, skipping" >&2
            exit 0
          fi

          if [ -e "$USER_KEY" ] && [ ! -L "$USER_KEY" ]; then
            # A real (non-symlink) file exists — guard against silent overwrites.
            echo "error: $USER_KEY already exists" >&2
            echo "       Remove or back up $USER_KEY manually if you want it managed by agenix." >&2
            exit 1
          fi

          mkdir -p "$(dirname "$USER_KEY")"
          ln -sf "$DECRYPTED" "$USER_KEY"
        '';
      };
    })
  ]);
}
