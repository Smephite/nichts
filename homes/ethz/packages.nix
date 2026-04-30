{
  pkgs,
  inputs,
  ...
}:  let
python-packages = ps:
  with ps; [
      pandas
      numpy
      opencv4
      ipython
      uv
      pyserial
    ]; in
  {

  home.packages = with pkgs; [
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
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
    attic-client

    # dev
    nixd
    alejandra
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
    nil
    zed-editor

    gh

    # util
    bash
    bat # cat
    eza # ls
    wget
    plocate # locate file in filesystem
    lsof
    zoxide # Fast cd command that learns your habits
    tldr # community man pages

  ];

}
