# which default packages to use for the system
{ inputs, outputs, profile-config, pkgs, ...}:

let 
  python-packages = ps: with ps; [
    pandas
    numpy
    opencv4
    ipython
  ];
in
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    (python3.withPackages python-packages)
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    nheko
    neovim
    typst
    cm_unicode
    eza # exa is unmaintained
    hwinfo
    zsh
    git
    broot
    unzip
    calc
    rsync
    # neofetch 
    # fastfetch has the option to set a timeout for
    #   for each module, which makes it dramatically faster
    #   as counting the number of packages takes over 800 (!!!) ms,
    #   which makes it very unpleasant to use as default thing
    #   to display when starting a terminal
    # fastfetch    
    zathura
    wlr-randr
    wget
    gnumake
    zoxide
    python3
    nodejs
    gcc
    cargo
    rustc
    rust-analyzer
    clippy
    lsof
    htop 
    okular
    smartmontools
    # networkmanager
    pkg-config
    sof-firmware # audio
    easyeffects
    nix-index
    # --------- optional
    gnome.eog
    sherlock
    xfce.thunar
    ranger
    nitch

    plocate
    alsa-utils
    foot

    # image manipulation
    gimp
    imagemagick

    telegram-desktop
    tg

    calc
    tldr


    # partition management
    parted
    gnufdisk
    lapce
  ];
}
