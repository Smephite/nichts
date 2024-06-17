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
      # 22 # git
    ];
    allowedUDPPortRanges = [
      # Some of these ports get assigned to discord...
      { from = 45000; to = 60000; }
    ];
  };
}
