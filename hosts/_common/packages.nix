{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    git-lfs

    bash
    rsync
    wget
    htop
    btop
    hwinfo

    unzip
    nano
    vim
    nitch
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
    autorestic
    smartmontools
    parted
    attic-client
  ];
}
