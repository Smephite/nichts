{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.git;
  allowedSignersFile = pkgs.writeText "git-allowed-signers" (
    concatMapStringsSep "\n" (key: "${cfg.userEmail} ${key}") cfg.signing.allowedKeys + "\n"
  );
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings =
        {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
          init.defaultBranch = cfg.defaultBranch;
          push.autoSetupRemote = true;
          commit.verbose = true;
          log.showSignature = true;
          merge.conflictstyle = "zdiff3";
          diff.algorithm = "histogram";
          transfer.fsckobjects = true;
          fetch.fsckobjects = true;
          receive.fsckobjects = true;
          pull.rebase = cfg.pullRebase;
        }
        // optionalAttrs (cfg.signing.key != null && cfg.signing.allowedKeys != []) {
          gpg.ssh.allowedSignersFile = "${allowedSignersFile}";
        };

      signing =
        {
          format =
            if cfg.signing.key != null
            then "ssh"
            else null;
        }
        // optionalAttrs (cfg.signing.key != null) {
          key = cfg.signing.key;
          signByDefault = cfg.signing.signByDefault;
        };
    };
  };
}
