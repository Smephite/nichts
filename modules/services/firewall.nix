{ pkgs, ... }: 
{
# TODO: Move this under system options
# TODO: Make option to enable / disable restrictive port ranges
networking.firewall = {
    enable = pkgs.lib.mkDefault true;
    allowedTCPPorts = [ 
      80 
      443
      9418 # git
      1194 # nordpnv
      1716 # KDE Connect

      # 22 # git
    ];
    allowedTCPPortRanges = [
      { from = 1739; to = 1741; } # KDE Connect
    ];


    allowedUDPPorts = [
      1716 # KDE CONNECT
    ];
    allowedUDPPortRanges = [
      # Some of these ports get assigned to discord...
      { from = 45000; to = 60000; }
    ];
  };
}
