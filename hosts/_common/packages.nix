{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    bash
    rsync
    wget
    htop
    btop
    hwinfo
    comma
    nix-index
    unzip
    nano
    vim
    nitch
    inputs.agenix.packages.${system}.default
    autorestic
    smartmontools
    parted
  ];
}
