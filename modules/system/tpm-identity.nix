{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.system.tpmIdentity;
in {
  options.modules.system.tpmIdentity = {
    enable = mkEnableOption "TPM-sealed agenix decryption identity via age-plugin-tpm";

    identityPath = mkOption {
      type = types.str;
      default = "/var/lib/agenix/tpm-identity";
      description = ''
        Path to the age-plugin-tpm identity file. The file contains an
        AGE-PLUGIN-TPM-... identity string wrapping a TPM-sealed key handle.
        The private material never leaves the TPM in cleartext.
      '';
    };

    recipientOut = mkOption {
      type = types.str;
      default = "/etc/tpm-recipient.txt";
      description = ''
        Where to write the public age recipient (age1tpm1...) after identity
        generation. Copy this string into secrets/ssh/host/<hostname>.age and
        run secrets/rekey.sh.
      '';
    };

    # age-plugin-tpm 1.0.1 does not yet expose PCR binding via CLI, so this
    # option is currently a documentation placeholder. Kept in the interface
    # so hosts can declare intent and we can wire it up when the plugin lands
    # PCR support without another rebuild-switch dance.
    pcrs = mkOption {
      type = types.listOf types.int;
      default = [];
      description = ''
        PCRs to seal the identity against. Empty list means seal to the TPM
        chip only (no policy binding); the key is unusable without this
        physical TPM but survives kernel/firmware updates and SecureBoot
        toggles. Non-empty binding is not yet wired to the plugin CLI.
      '';
    };
  };

  config = mkIf cfg.enable (let
    # age looks up `age-plugin-<name>` via PATH. Agenix invokes age by
    # absolute store path from an activation script whose PATH is minimal
    # (coreutils, util-linux — not environment.systemPackages), so the
    # plugin is invisible unless we inject it into the age process's own
    # environment. Wrap age so every agenix call finds the plugin, without
    # touching upstream agenix or activation PATH.
    ageWithTpm = pkgs.writeShellScript "age-with-tpm" ''
      export PATH="${pkgs.age-plugin-tpm}/bin:$PATH"
      exec ${pkgs.age}/bin/age "$@"
    '';
  in {
    environment.systemPackages = [pkgs.age-plugin-tpm];

    age.ageBin = "${ageWithTpm}";
    age.identityPaths = mkOverride 800 [cfg.identityPath];

    # Run before agenix decrypts. Injecting the dep on agenixNewGeneration is
    # enough — agenixInstall transitively waits.
    system.activationScripts.agenixNewGeneration.deps = ["tpmIdentity"];

    system.activationScripts.tpmIdentity = {
      deps = ["specialfs"];
      text = ''
        IDENTITY="${cfg.identityPath}"
        RECIPIENT_OUT="${cfg.recipientOut}"
        PLUGIN="${pkgs.age-plugin-tpm}/bin/age-plugin-tpm"

        mkdir -p "$(dirname "$IDENTITY")"
        chmod 0700 "$(dirname "$IDENTITY")"

        if [ ! -s "$IDENTITY" ]; then
          echo "[tpmIdentity] generating new TPM-sealed identity at $IDENTITY" >&2
          umask 0077
          if ! "$PLUGIN" --generate -o "$IDENTITY" >&2; then
            echo "[tpmIdentity] ERROR: age-plugin-tpm failed to generate identity" >&2
            rm -f "$IDENTITY"
            exit 1
          fi
          chmod 0600 "$IDENTITY"
        fi

        # Derive the recipient by asking the TPM to unwrap the sealed
        # identity. Doubles as a health check: if the TPM was cleared, the
        # chip swapped, or the file corrupted, --convert fails here and the
        # rebuild aborts loudly instead of agenix failing weirdly later.
        mkdir -p "$(dirname "$RECIPIENT_OUT")"
        if RECIPIENT=$("$PLUGIN" --convert < "$IDENTITY" 2>&1); then
          printf '%s\n' "$RECIPIENT" > "$RECIPIENT_OUT"
          chmod 0644 "$RECIPIENT_OUT"
        else
          echo "[tpmIdentity] ERROR: TPM cannot unwrap $IDENTITY" >&2
          echo "[tpmIdentity] ($RECIPIENT)" >&2
          echo "[tpmIdentity] Likely causes: TPM cleared, chip swapped, or file corrupt." >&2
          rm -f "$RECIPIENT_OUT"
          exit 1
        fi
      '';
    };
  });
}
