{
  config,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./packages.nix
    ./wireguard.nix
  ];

  age.secrets.nylon_central.file = self + "/secrets/nylon.central.age";
  age.secrets.nylon_key.file = self + "/secrets/nylon." + config.networking.hostName + ".age";

  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_28;
    daemon.settings = {
      live-restore = false;
      data-root = "/var/lib/docker";
      default-address-pools = [
        {
          base = "172.30.0.0/16";
          size = 23;
        }
      ];
    };

    storageDriver = "overlay2";

    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  services = {
    logrotate.checkConfig = false;
    glusterfs = {
      enable = true;
    };
    nylon-wg = {
      enable = true;
      centralConfig = config.age.secrets.nylon_central.path;
      node = {
        id = config.networking.hostName + "." + config.networking.domain;
        key = config.age.secrets.nylon_key.path;
      };
      openFirewall = true;
    };
  };

  modules.other.home-manager.enable = true;

  networking = {
    hostName = "starhaven";
    domain = "core.kai.run";

    firewall = {
      allowedUDPPorts = [
        57175 # nylon
      ];
      trustedInterfaces = ["nylon"];
    };
    # Interfaces
    interfaces.eth0 = {
      macAddress = "00:50:56:5d:24:92";
      ipv6.addresses = [
        {
          address = "2a02:c207:3018:0000:0000:0000:0000:0001";
          prefixLength = 64;
        }
      ];
      ipv4.addresses = [
        {
          address = "109.123.248.65";
          prefixLength = 20;
        }
      ];
    };

    defaultGateway = {
      address = "109.123.240.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    nameservers = ["213.136.95.10" "213.136.95.11" "2a02:c207::1:53"];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
