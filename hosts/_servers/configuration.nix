{lib, ...}: {
  security.sudo.wheelNeedsPassword = false;

  age.identityPaths = ["/srv/host_keys/id_ed25519"];
  services.fail2ban.enable = true;

  # nix-index and comma each pull a package index from GitHub releases (~100 MB
  # for the full one). They're interactive conveniences with no use on a
  # headless box, and fetching them has been a recurring cause of build
  # failures here. Both are enabled in ../_common for workstations; turn them
  # off again for servers.
  programs.nix-index.enable = lib.mkForce false;
  programs.nix-index-database.comma.enable = lib.mkForce false;

  # See ../../modules
  modules = {
    programs = {
      fish.enable = lib.mkDefault true;
    };

    system = {
      server = true;
      # Automatically populate authorized_keys for root and ${username} with default keys
      #authorizedKeys.enable = lib.mkDefault true;
      gitPath = lib.mkDefault "/srv/nichts";
    };

    services = {
      ssh-notify.enable = lib.mkDefault true;
      autoUpdate.enable = lib.mkDefault true;
    };

    other.home-manager.enable = lib.mkDefault false;
  };
}
