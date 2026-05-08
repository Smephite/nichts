{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.forgejo-runner;
in {
  options.modules.services.forgejo-runner = {
    enable = mkEnableOption "Forgejo Actions runner";

    package = mkPackageOption pkgs "forgejo-runner" {};

    name = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Identifier reported to the Forgejo instance.";
    };

    url = mkOption {
      type = types.str;
      description = "Base URL of the Forgejo instance to register against.";
    };

    tokenFile = mkOption {
      type = types.path;
      description = ''
        Path to an environment file containing the registration token as
        `TOKEN=<value>`. Consumed once during runner registration.
      '';
    };

    labels = mkOption {
      type = types.listOf types.str;
      default = [
        "native:host"
        "debian-latest:docker://node:20-bookworm"
        "ubuntu-latest:docker://node:20-bookworm"
        "nixos-latest:docker://nixos/nix"
      ];
      description = "Labels mapping job runtimes to execution environments.";
    };
  };

  config = mkIf cfg.enable {
    services.gitea-actions-runner = {
      package = cfg.package;
      instances.${cfg.name} = {
        enable = true;
        inherit (cfg) name url tokenFile labels;
        hostPackages = with pkgs; [
          bash
          coreutils
          curl
          gawk
          gitMinimal
          gnused
          nodejs
          wget
          nix
          attic-client
        ];
      };
    };
  };
}
