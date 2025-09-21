{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  age.secrets.wg-key-starhaven = {
    file = "${self}/secrets/wg.starhaven.age";
  };
  age.secrets.wg-preshared = {
    file = "${self}/secrets/wg.preshared.age";
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ "wg0" ];

  boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
  };

  # enable NAT
#  networking.nat = {
#    enable = true;
#    enableIPv6 = true;
#    externalInterface = "eth0";
#    internalInterfaces = [ "wg0" ];
#  };
networking.wireguard = {
    enable = true;
    interfaces = {
      wg0 = {
        # the IP address and subnet of this peer
        ips = [ "172.24.0.1/16" ];

        listenPort = 51820;
        privateKeyFile = config.age.secrets.wg-key-starhaven.path;

        peers = [
          { 
            name = "woolyhood.core.kai.run";
            allowedIPs = [  "172.24.5.0/24" ];
            publicKey = "xIj6uq1OrygFvsSRRL5b5NJc5cv5h7P5tic46k3O1Vs=";
            presharedKeyFile = config.age.secrets.wg-preshared.path;
#            endpoint = "wollyhood.ext.kai.run:51820";
            persistentKeepalive = 25;
          }
          { 
            name = "knwoe.core.kai.run";
            allowedIPs = [ "172.24.6.0/24" "192.168.200.0/22" ];
            publicKey = "KDQibeYB65zibw/MOsNspi9bO8FXfXXPclk1ZlP0yzo=";
            presharedKeyFile = config.age.secrets.wg-preshared.path;
            endpoint = "qiyodurfj6peb430.myfritz.net:56011";
            persistentKeepalive = 25;
          }
        ];

              # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      '';
        #${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
        #${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o eth0 -j MASQUERADE

      # Undo the above
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
      '';
        #${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
        #${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o eth0 -j MASQUERADE
      };
    };
};
}