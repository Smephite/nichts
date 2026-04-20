{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib; let
  cfg = config.modules.system.sshCA;
  caKeyFile = self + "/secrets/ssh/ca.pub";
  krlFile = self + "/secrets/ssh/krl";

  # environment.etc copies the file (rather than symlinking) when mode is set
  # to anything other than "symlink".  This gives sshd a real file under
  # /etc/ssh/ with no /nix/store ancestry, satisfying its path-safety check
  # for AuthorizedPrincipalsCommand (which rejects paths through group-writable
  # directories — /nix/store is root:nixbld 1775).
  principalsScript = pkgs.writeShellScript "ssh-principals" ''
    echo "$1"
    echo "*"
  '';
  principalsScriptPath = "/etc/ssh/ssh-principals";
in {
  options.modules.system.sshCA = {
    enable = mkEnableOption "Trust the repository SSH CA for user authentication";
  };

  config = mkIf cfg.enable {
    environment.etc."ssh/ca.pub" = {
      source = caKeyFile;
      mode = "0444";
    };

    environment.etc."ssh/revoked_keys" = {
      source = krlFile;
      mode = "0444";
    };

    environment.etc."ssh/ssh-principals" = {
      source = principalsScript;
      mode = "0555";
    };

    services.openssh.extraConfig = ''
      TrustedUserCAKeys /etc/ssh/ca.pub
      AuthorizedPrincipalsCommand ${principalsScriptPath} %u
      AuthorizedPrincipalsCommandUser nobody
      RevokedKeys /etc/ssh/revoked_keys
    '';
  };
}
