{
  pkgs,
  pkgs-unstable,
  ...
}: let
  python-packages = ps:
    with ps; [
      pandas
      numpy
      opencv4
      ipython
      uv
      pyserial
    ];
in {
  environment.systemPackages = with pkgs; [
    # communication
    pkgs-unstable.signal-desktop
    wasistlos # whatsapp
    slack
    mattermost-desktop
    discord
    zoom-us
    teams-for-linux

    # storage
    nextcloud-client

    # office
    libreoffice
    thunderbird
    obsidian
    zotero
    typst
    evince # GNOME's document viewer
    firefox

    # Security
    pkgs-unstable.yubioath-flutter
    age-plugin-yubikey

    # media
    spotify
    vlc
    gimp

    # Audio drivers
    sof-firmware
    alsa-utils

    # dev
    nixd
    alejandra
    vscodium
    gnumake
    python3
    (python3.withPackages python-packages)
    nodejs
    gcc
    gdb
    cargo
    rustc
    rust-analyzer
    clippy
    radicle-desktop
    radicle-tui

    # util
    bash
    bat # cat
    eza # ls
    wget
    plocate # locate file in filesystem
    lsof
    zoxide # Fast cd command that learns your habits
    nautilus # File manager for GNOME
    tldr # community man pages
    usbutils
    pciutils

  ];
}
