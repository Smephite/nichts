{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [
    ../servers/default.nix
    ./packages.nix
    ./wireguard.nix
  ];


  modules.service.nylon = {
    enable = true;
  };


  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_28;
    daemon.settings = {
      live-restore = false;
      data-root = "/srv/docker/daemon/";
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

  services.logrotate.checkConfig = false;

  modules.other.home-manager.enable = true;

  networking = {
    hostName = "starhaven";
    domain = "core.kai.run";

    firewall = {
        allowedUDPPorts = [
           57175 # nylon
          ];  
        trustedInterfaces = [ "nylon" ];
    };
    # Interfaces
    interfaces.eth0 = {
      macAddress = "00:50:56:5d:24:92";
      ipv6.addresses = [{
        address = "2a02:c207:3018:0000:0000:0000:0000:0001";
        prefixLength = 64;
      }];
      ipv4.addresses = [{
        address = "109.123.248.65";
        prefixLength = 20;
      }];
    };

    defaultGateway = {
      address = "109.123.240.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    nameservers = [ "213.136.95.10" "213.136.95.11" "2a02:c207::1:53"];
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}