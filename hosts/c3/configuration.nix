{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./packages.nix
  ];

  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  services.qemuGuest.enable = true;
  services.fstrim.enable = true;

  users.users.atticd = {
    isSystemUser = true;
    group = "atticd";
  };
  users.groups.atticd = {};

  age.secrets.attic-credentials = {
    file = self + "/secrets/attic.c3.age";
    owner = "atticd";
    group = "atticd";
    mode = "0400";
  };

  systemd.services.atticd.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "atticd";
    Group = "atticd";
  };

  services = {
    whoami = {
      enable = true;
      port = 8413;
    };

    atticd = {
      enable = true;
      environmentFile = config.age.secrets.attic-credentials.path;

      settings = {
        listen = "[::]:11974";
        api-endpoint = "https://cache.app.kai.run/";
        allowed-hosts = ["cache.app.kai.run"];
        database.url = "sqlite:///var/lib/atticd/db.sqlite";

        storage = {
          type = "local";
          path = "/var/lib/atticd/storage";
        };

        garbage-collection = {
          interval = "12 hours";
          default-retention-period = "90 days";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [11974];

  modules = {
    services.caddy.enable = true;
    other.home-manager.enable = true;
    system.network.nylon-wg = {
      enable = true;
      node.key = config.age.secrets.nylon_key.path;
    };
  };

  networking = {
    hostName = "c3";
    domain = "aurora.core.kai.run";
    useDHCP = lib.mkDefault true;
  };

  system.stateVersion = "25.05";
}
