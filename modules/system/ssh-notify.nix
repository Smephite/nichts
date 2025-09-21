{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.ssh-notify;
  username = config.modules.system.username;
in {

#   security.pam.services.sshd.rules.session = {
#            name = "login_msg";
#            enable = true;
#            control = "optional";
#            order = 1;
#            modulePath = "${pkgs.pam.outPath}/lib/security/pam_exec.so";
#            args = ["echo" "Welcome to Nichts-Server!"];
#    };

}