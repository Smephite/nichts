# blatantly stolen from github.com/bloxx12/nichts
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.nh;
  gitPath = config.modules.system.gitPath;

  # Shell-agnostic wrapper that intercepts `nh os switch/boot/test` and
  # verifies every commit reachable from HEAD is signed by a trusted key
  # (%G? == "G") before delegating to the real nh binary.
  # pkgs.hiPrio ensures this shadows the nh binary installed by programs.nh.
  nhWrapper = lib.hiPrio (pkgs.writeShellApplication {
    name = "nh";
    runtimeInputs = [pkgs.git pkgs.gawk];
    text = ''
      if [ "$#" -ge 2 ] && [ "$1" = "os" ]; then
        case "$2" in
          switch|boot|test)
            unsigned=$(git -C ${gitPath} log --format="%H %G?" HEAD \
              | gawk '$2 != "G" { print $1 }')

            if [ -n "$unsigned" ]; then
              echo "⚠  Warning: unsigned or untrusted commits in history:"
              while IFS= read -r commit; do
                echo "  $(git -C ${gitPath} log --format="%h %s" -1 "$commit")"
              done <<< "$unsigned"
              echo ""

              if [ -t 0 ]; then
                read -r -p "Proceed with build anyway? [y/N] " reply
                case "$reply" in
                  [yY]) ;;
                  *) echo "Aborted."; exit 1 ;;
                esac
              else
                echo "Non-interactive session — aborting due to unsigned commits." >&2
                exit 1
              fi
            fi
          ;;
        esac
      fi

      exec ${pkgs.nh}/bin/nh "$@"
    '';
  });
in {
  options.modules.programs.nh.enable = mkEnableOption "nh";

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = gitPath;
    };

    environment.systemPackages = [nhWrapper];
  };
}
