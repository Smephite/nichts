{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../common/default.nix
    ./packages.nix
  ];

   services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
    };
   };

#   security.pam.services.sshd.rules.session = {
#            name = "login_msg";
#            enable = true;
#            control = "optional";
#            order = 1;
#            modulePath = "${pkgs.pam.outPath}/lib/security/pam_exec.so";
#            args = ["echo" "Welcome to Nichts-Server!"];
#    };

   services.fail2ban.enable = true;

   users.users.root.openssh.authorizedKeys.keys = config.authorizedKeys.default;
}
