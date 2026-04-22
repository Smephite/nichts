{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.modules.system.sshKey;
  username = config.modules.system.username;

  hostname = config.networking.hostName;
  secretName = "ssh-${hostname}";
  ageFile = self + "/secrets/ssh/user/${hostname}.age";
  ageFileExists = builtins.pathExists ageFile;

  userKeyName = "id_ed25519";
  userKeyPath = "/home/${username}/.ssh/${userKeyName}";
  userPubKeyPath = "/home/${username}/.ssh/${userKeyName}.pub";
  userCertKeyPath = "/home/${username}/.ssh/${userKeyName}-cert.pub"; # SSH expects this exact filename

  pubKeyFile = self + "/secrets/ssh/user/${hostname}.pub";
  certKeyFile = self + "/secrets/ssh/user/${hostname}.cert";
  pubKeyFileExists = builtins.pathExists pubKeyFile;
  certKeyFileExists = builtins.pathExists certKeyFile;
in {
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
      age.identityPaths = mkOverride 900 ["/etc/ssh/ssh_host_ed25519_key"];
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

          # Back up any externally-managed key before taking over.
          # A symlink means we already own it; a real file is from outside.
          if [ -e "$USER_KEY" ] && [ ! -L "$USER_KEY" ]; then
            echo "sshKeyFromSecret: backing up existing $USER_KEY to ${userKeyPath}.bak" >&2
            mv "$USER_KEY" "${userKeyPath}.bak"
          fi

          mkdir -p "$(dirname "$USER_KEY")"
          ln -sf "$DECRYPTED" "$USER_KEY"

          ${optionalString pubKeyFileExists ''
            ln -sf "${pubKeyFile}" "${userPubKeyPath}"
          ''}

          ${optionalString certKeyFileExists ''
            ln -sf "${certKeyFile}" "${userCertKeyPath}"
          ''}
        '';
      };
    })
  ]);
}
