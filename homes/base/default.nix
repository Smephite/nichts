{
  lib,
  config,
  ...
}: let
  user = "msc25h18";
  realHome = "/home/${user}";
in {
  imports = [
    ../_common
  ];

  home.username = user;
  home.homeDirectory = "${realHome}/nix-home";

  modules.programs = {
    git = {
      enable = lib.mkDefault true;
      userName = lib.mkDefault "Kai Berszin";
      userEmail = lib.mkDefault "kberszin@iis.ee.ethz.ch";
      defaultBranch = lib.mkDefault "main";
      pullRebase = lib.mkDefault true;
    };
    nh.flakePath = lib.mkDefault "${config.home.homeDirectory}/repos/nichts";
  };
}
