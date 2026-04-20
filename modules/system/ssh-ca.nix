{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.modules.system.sshCA;
  caKeyFile = self + "/secrets/ssh/ca.pub";
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
      AuthorizedPrincipalsCommand /bin/sh -c 'echo "$1"; echo "*"' sh %u
      AuthorizedPrincipalsCommandUser nobody
    '';
  };
}
