{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    git
    rsync
    wget
    htop
    hwinfo
    nix-index
    nano
    vim
    nitch
    plocate

  ];
}