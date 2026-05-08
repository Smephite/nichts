{
  pkgs,
  inputs,
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
  home.packages = with pkgs; [
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
    attic-client

    # dev
    nixd
    alejandra
    gnumake
    (python3.withPackages python-packages)
    nodejs
    gcc
    gdb
    cargo
    rustc
    rust-analyzer
    clippy
    nil
  ];
}
