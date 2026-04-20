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

  # Script lives in the Nix store — owned by root, not group/world-writable,
  # which satisfies sshd's AuthorizedPrincipalsCommand security requirements.
  # %u is expanded by sshd and passed as $1; keeping it out of sshd_config
  # avoids sshd's double-quoted token expansion mangling "$1" into "".
  principalsScript = pkgs.writeShellScript "ssh-principals" ''
    echo "$1"
    echo "*"
  '';
in {
  options.modules.system.sshCA = {
    enable = mkEnableOption "Trust the repository SSH CA for user authentication";
  };

  config = mkIf cfg.enable {
    environment.etc."ssh/ca.pub" = {
      source = caKeyFile;
      mode = "0444";
    };

    services.openssh.extraConfig = ''
      TrustedUserCAKeys /etc/ssh/ca.pub
      AuthorizedPrincipalsCommand ${principalsScript} %u
      AuthorizedPrincipalsCommandUser nobody
    '';
  };
}
