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

   services.openssh.enable = true;
   users.users.root.openssh.authorizedKeys.keys = authorizedKeys.default;
}