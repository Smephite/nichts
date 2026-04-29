{lib, ...}:
with lib; {
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
      default = "main";
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
          as this identity.
        '';
      };
    };
  };
}
