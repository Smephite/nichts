{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.modules.programs.rbw;
  username = config.modules.system.username;

  secretName = "rbw-config";
  ageFile = self + "/secrets/rbw.age";
  ageFileExists = builtins.pathExists ageFile;

  configDir = "/home/${username}/.config/rbw";
  configPath = "${configDir}/config.json";
in {
  options.modules.programs.rbw = {
    enable = mkEnableOption "agenix-managed rbw (Bitwarden CLI) configuration";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      warnings =
        optional (!ageFileExists)
        "modules.programs.rbw: ${toString ageFile} does not exist; rbw config will not be managed";
    }

    (mkIf ageFileExists {
      age.secrets.${secretName} = {
        file = ageFile;
        owner = username;
        mode = "0600";
      };

      system.activationScripts.rbwConfig = {
        deps = [
          "agenix"
          "users"
          "groups"
        ];
        text = ''
          DECRYPTED="/run/agenix/${secretName}"
          CONFIG="${configPath}"

          if [ ! -f "$DECRYPTED" ]; then
            echo "rbwConfig: $DECRYPTED not found, skipping" >&2
            exit 0
          fi

          mkdir -p "${configDir}"
          chown ${username} "${configDir}"
          chmod 700 "${configDir}"

          # Back up any manually created config before taking over.
          if [ -e "$CONFIG" ] && [ ! -L "$CONFIG" ]; then
            echo "rbwConfig: backing up existing $CONFIG to ${configPath}.bak" >&2
            mv "$CONFIG" "${configPath}.bak"
          fi

          ln -sf "$DECRYPTED" "$CONFIG"
        '';
      };
    })
  ]);
}
