{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    alejandra
    nixd
    tcpdump
    wireguard-tools
    attic-client
    attic-server
  ];
}
