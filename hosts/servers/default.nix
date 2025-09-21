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
   users.users.root.openssh.authorizedKeys.keys = config.authorizedKeys.default ++ [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPnDKM5e9Ukn3dJEW6UzoryatqXgg9uqmiOQSA1ubG1k8MDISvmgisxaCPjk5qUaHSijc5amMAZytVLrcHHPmb716w7CitVvu3As/s+sSjbgVCroiugvdSO25sE8UXrLS1JqC2pBvdqgjgYiR8QHaxlkpUCaIfyWsBG4CwU9QZcxX5ZBCKLCKZr8ntSEWRMyywxjfhZxSPjE+wwPoqSwBhmIhFjFV6vhrQ/gxgfuS/+Sp/HfpbT93lOuxXxiB4PL5qGabh+Udp3Q6S6uhV/Bx7oEPJA7hlVPkU1g2+pJBu76UglpnHnTW0l8SqXv9lm6Pu13o3ZfaXfyw4adoIBa2V Kai@Kai-PC" ];
}
