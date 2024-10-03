# which default packages to use for the system
{pkgs, ...}: let
  python-packages = ps:
    with ps; [
      pandas
      numpy
      opencv4
      ipython
    ];
in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    (python3.withPackages python-packages)
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # nheko
    neovim
    typst
    prismlauncher
    cm_unicode
    eza # exa is unmaintained
    hwinfo
    git
    broot
    unzip
    calc
    rsync
    okular
    wlr-randr
    wget
    gnumake
    zoxide
    python3
    nodejs
    gcc
    gdb
    cargo
    rustc
    rust-analyzer
    clippy
    lsof
    htop
    smartmontools
    # networkmanager
    pkg-config
    sof-firmware # audio
    # easyeffects currently throws an error
    nix-index
    # --------- optional
    gnome.eog
    sherlock
    nautilus
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

    kdeconnect
    yazi

    # nix formatter
    alejandra
  ];
}
