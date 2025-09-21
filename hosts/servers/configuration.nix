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
    system = rec {
      # Automatically populate authorized_keys for root and ${username} with default keys
      authorizedKeys.enable = true;
      username = "kai";
      gitPath = lib.mkDefault "/srv/nichts-server";
    };
    other.home-manager = {
      enable = lib.mkDefault false;
    };
  };
}