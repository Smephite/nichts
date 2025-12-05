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
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
    autorestic
    smartmontools
    parted
  ];
}
