{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Dev
    nixfmt
    alejandra
    nixd
    tcpdump
  ];
}
