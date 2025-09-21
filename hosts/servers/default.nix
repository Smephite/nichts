{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../common/default.nix
    ./configuration.nix
    ./packages.nix
  ];

   services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
    };
   };

   services.fail2ban.enable = true;

   users.users.root.openssh.authorizedKeys.keys = config.authorizedKeys.default;
}
