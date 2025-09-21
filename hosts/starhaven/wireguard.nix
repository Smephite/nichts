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

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.enable = true;

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
        ips = [ "172.23.0.1/24" ];

        listenPort = 51820;
        privateKeyFile = config.age.secrets.wg-key-starhaven.path;

        peers = [
          { 
            name = "woolyhood.core.kai.run";
            publicKey = "xIj6uq1OrygFvsSRRL5b5NJc5cv5h7P5tic46k3O1Vs=";
            allowedIPs = [ "172.23.0.5/32" "172.24.5.0/24" ];
#            endpoint = "wollyhood.ext.kai.run:51820";
            persistentKeepalive = 25;
          }
          { 
            name = "knwoe.core.kai.run";
            publicKey = "KDQibeYB65zibw/MOsNspi9bO8FXfXXPclk1ZlP0yzo=";
            allowedIPs = [ "192.168.200.1/32" "192.168.200.0/22" ];
            presharedKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            endpoint = "qiyodurfj6peb430.myfritz.net:56011";
            persistentKeepalive = 25;
          }
        ];

              # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 172.23.0.0/24 -o eth0 -j MASQUERADE
      '';
        #${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
        #${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o eth0 -j MASQUERADE

      # Undo the above
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 172.23.0.0/24 -o eth0 -j MASQUERADE
      '';
        #${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
        #${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o eth0 -j MASQUERADE
      };
    };
};
}