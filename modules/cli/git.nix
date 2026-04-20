{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.git;
  username = config.modules.system.username;

  allowedSignersFile = pkgs.writeText "git-allowed-signers" (
    concatMapStringsSep "\n" (key: "${cfg.userEmail} ${key}") cfg.signing.allowedKeys + "\n"
  );
in {
  options.modules.programs.git = {
    enable = mkEnableOption "git";
    userName = mkOption {
      type = types.str;
      description = "git username";
    };
    userEmail = mkOption {
      type = types.str;
      description = "git email";
    };
    editor = mkOption {
      type = types.str;
      default = "$EDITOR";
      description = "commit message editor";
    };
    defaultBranch = mkOption {
      type = types.str;
      default = "master";
      description = "default git branch";
    };
    pullRebase = mkOption {
      type = types.bool;
      default = false;
      description = "git config pull.rebase";
    };

    signing = {
      key = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to the SSH public key file for signing (e.g. "~/.ssh/id_ed25519.pub"),
          or a literal key with the "key::" prefix. null disables SSH signing.
        '';
      };
      signByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Sign all commits and tags by default.";
      };
      allowedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          SSH public key strings (authorised_keys format) trusted to sign commits
          as this identity. Used to populate the allowed_signers file that git
          needs for signature verification.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = mkIf config.modules.other.home-manager.enable {
      programs.git = {
        enable = cfg.enable;
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

        # Always set format explicitly — even as null — so home-manager never
        # falls through to its stateVersion-dependent default and emits a warning.
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

    programs.git = mkIf (!config.modules.other.home-manager.enable) {
      enable = cfg.enable;
    };
  };
}
