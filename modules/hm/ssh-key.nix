{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.modules.system.sshKey;

  hostname = cfg.hostname;
  secretName = "ssh-${hostname}";
  ageFile = self + "/secrets/ssh/user/${hostname}.age";
  ageFileExists = builtins.pathExists ageFile;

  userKeyName = "id_ed25519";
  userKeyPath = "${config.home.homeDirectory}/.ssh/${userKeyName}";
  userPubKeyPath = "${config.home.homeDirectory}/.ssh/${userKeyName}.pub";
  userCertKeyPath = "${config.home.homeDirectory}/.ssh/${userKeyName}-cert.pub"; # SSH expects this exact filename

  pubKeyFile = self + "/secrets/ssh/user/${hostname}.pub";
  certKeyFile = self + "/secrets/ssh/user/${hostname}.cert";
  pubKeyFileExists = builtins.pathExists pubKeyFile;
  certKeyFileExists = builtins.pathExists certKeyFile;
in {
  options.modules.system.sshKey = {
    enable = mkEnableOption "agenix-managed SSH identity key (${userKeyPath})";
    hostname = mkOption {
      type = types.str;
      description = "hostname used for secret file lookup (secrets/ssh/user/<hostname>.age)";
    };
    # On NixOS the host key solves the chicken-and-egg problem because agenix
    # runs as root before the user key exists.  Here you must supply an identity
    # that is already present on the machine — a dedicated age key, a YubiKey,
    # or any SSH key that is NOT itself managed by this module.
    identityPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Age identity paths used to decrypt the SSH key secret.
        Must not include the key being managed (chicken-and-egg).
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      warnings =
        optional (!ageFileExists)
        "modules.system.sshKey: ${ageFile} does not exist; SSH key will not be managed by agenix on this host"
        ++ optional (cfg.identityPaths == [])
        "modules.system.sshKey: identityPaths is empty; set it to an identity that can decrypt ${ageFile}";
    }

    (mkIf ageFileExists {
      age.secrets.${secretName} = {
        file = ageFile;
        mode = "0600";
        # No custom path — agenix writes to its own secrets dir.
        # Placement is handled by the activation script below.
      };

      home.activation.sshKeyFromSecret = lib.hm.dag.entryAfter ["writeBoundary"] ''
        DECRYPTED="${config.age.secrets.${secretName}.path}"
        USER_KEY="${userKeyPath}"

        if [ ! -f "$DECRYPTED" ]; then
          echo "sshKeyFromSecret: $DECRYPTED not found, skipping" >&2
          exit 0
        fi

        # Back up any externally-managed key before taking over.
        # A symlink means we already own it; a real file is from outside.
        if [ -e "$USER_KEY" ] && [ ! -L "$USER_KEY" ]; then
          echo "sshKeyFromSecret: backing up existing $USER_KEY to ${userKeyPath}.bak" >&2
          $DRY_RUN_CMD mv "$USER_KEY" "${userKeyPath}.bak"
        fi

        $DRY_RUN_CMD mkdir -p "$(dirname "$USER_KEY")"
        $DRY_RUN_CMD ln -sf "$DECRYPTED" "$USER_KEY"

        ${optionalString pubKeyFileExists ''
          $DRY_RUN_CMD ln -sf "${pubKeyFile}" "${userPubKeyPath}"
        ''}

        ${optionalString certKeyFileExists ''
          $DRY_RUN_CMD ln -sf "${certKeyFile}" "${userCertKeyPath}"
        ''}
      '';
    })
  ]);
}
