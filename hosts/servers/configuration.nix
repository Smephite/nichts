{
  config,
  pkgs,
  lib,
  ...
}: let
  username = config.modules.system.username;
in {
  security.sudo.wheelNeedsPassword = false;

  # Allow ssh connections
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
    };
  };

  services.fail2ban.enable = true;

  # See ../../modules
  modules = {
    system = {
      # Automatically populate authorized_keys for root and ${username} with default keys
      authorizedKeys.enable = true;
      username = "kai";
      gitPath = lib.mkDefault "/etc/nixos/nichts-server";
    };
    other.home-manager = {
      enable = false;
    };
  };
}