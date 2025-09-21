{
  config,
  pkgs,
  lib,
  ...
}: let
  username = config.modules.system.username;
in {
  # If set, the calling user’s SSH agent is used to authenticate against the keys in the calling user’s ~/.ssh/authorized_keys
  security.pam.services.sshd.sshAgentAuth = true;

  # Allow ssh connections
  services.openssh = {
  enable = true;
  settings = {
    PermitRootLogin = "prohibit-password";
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