{pkgs, ...}: {
  home.packages = with pkgs; [
    nix
    git
    git-lfs

    bash
    rsync
    wget
    htop
    btop

    unzip
    nano
    vim
    nitch

    gh

    # util
    bat
    eza
    plocate
    lsof
    zoxide
    tldr
  ];
}
