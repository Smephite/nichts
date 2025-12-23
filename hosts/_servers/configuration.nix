{lib, ...}: {
  security.sudo.wheelNeedsPassword = false;

  age.identityPaths = ["/srv/host_keys/id_ed25519"];
  services.fail2ban.enable = true;

  # See ../../modules
  modules = {
    programs = {
      fish.enable = lib.mkDefault true;
    };

    system = {
      server = true;
      # Automatically populate authorized_keys for root and ${username} with default keys
      authorizedKeys.enable = lib.mkDefault true;
      gitPath = lib.mkDefault "/srv/nichts";
    };

    services = {
      ssh-notify.enable = lib.mkDefault true;
    };

    other.home-manager.enable = lib.mkDefault false;
  };
}
