{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./packages.nix
  ];

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nano";
  };

  systemd.user.startServices = false;

  programs.nix-index-database.comma.enable = true;

  modules.programs = {
    fish.enable = lib.mkDefault true;
    starship.enable = lib.mkDefault true;
    atuin.enable = lib.mkDefault true;
    nh.enable = lib.mkDefault true;
  };

  nix.package = pkgs.nix;
  nix.settings = {
    use-sqlite-wal = false;
    fsync-metadata = false;
    sandbox = false;
    extra-experimental-features = [
      "flakes"
      "nix-command"
    ];
    extra-substituters = [
      "https://cache.kai.run/nixos"
      "https://zed.cachix.org"
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "nixos:m1C4Znb4JdZre2SJyregJz/kDU3ELalD8qEJc/dP0KE="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    warn-dirty = false;
  };

  xdg.enable = true;
}
