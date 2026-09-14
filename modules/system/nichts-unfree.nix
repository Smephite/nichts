{
  config,
  lib,
  inputs,
  self,
  ...
}:
with lib; let
  cfg = config.modules.system.nichtsUnfree;

  secretName = "github-unfree-deploy";
  ageFile = self + "/secrets/${secretName}.age";

  # The deploy key is an agenix secret, so every host that wants it has to be a
  # recipient. Adding a host means rekeying (`agenix -r` in ./secrets), which is
  # easy to forget — catch it at eval time instead of at activation.
  hostname = config.networking.hostName;
  hostKeyName = "host-${hostname}";
  publicKeys = import (self + "/secrets/ssh/public_keys.nix");
  recipients = (import (self + "/secrets/secrets.nix"))."${secretName}.age".publicKeys;
  isRecipient =
    publicKeys ? ${hostKeyName} && elem publicKeys.${hostKeyName} recipients;
in {
  options.modules.system.nichtsUnfree = {
    enable = mkEnableOption "the nichts-unfree overlay (private/unfree packages)";

    deployKey = mkEnableOption ''
      a root-owned read-only GitHub deploy key for the nichts-unfree flake
      input. Needed on hosts that evaluate the flake as root — anything
      rebuilding itself through modules.services.autoUpdate — because root has
      no GitHub key of its own and the input is fetched over git+ssh.
      Interactive hosts, where you build as yourself, do not need it
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Take unfree packages through the overlay rather than
      # `inputs.nichts-unfree.packages.*`: the latter is built by that flake's
      # own nixpkgs instance, which carries no config and so refuses to
      # evaluate unfree licenses regardless of `nixpkgs.config.allowUnfree`.
      nixpkgs.overlays = [inputs.nichts-unfree.overlays.default];
    }

    (mkIf cfg.deployKey {
      warnings =
        optional (!isRecipient)
        "modules.system.nichtsUnfree.deployKey: ${hostname} is not a recipient of ${secretName}.age; add ${hostKeyName} to secrets/secrets.nix and rekey, or root will not be able to fetch the nichts-unfree input";

      age.secrets.${secretName} = {
        file = ageFile;
        mode = "0400";
      };

      programs.ssh = {
        extraConfig = ''
          Match user root host github.com
            IdentityFile ${config.age.secrets.${secretName}.path}
            IdentitiesOnly yes
        '';

        # Root has no known_hosts and a non-interactive fetch cannot answer a
        # host-key prompt. Key taken from https://api.github.com/meta.
        knownHosts.github-com = {
          hostNames = ["github.com"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
      };
    })
  ]);
}
