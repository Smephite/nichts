{
  inputs,
  lib,
  pkgs,
  self,
  config,
  ...
}:
let
  username = config.modules.system.username;
in
{
  # partly taken from github.com/bloxx12/nichts

  age.secrets.github-ro-token = {
    file = "${self}/secrets/github-ro.age";
    owner = username;
    mode = "0400";
  };

  nix = {
    extraOptions = ''
      !include ${config.age.secrets.github-ro-token.path}
    '';
    settings = {
      extra-substituters = [
        "https://zed.cachix.org"
        "https://cache.garnix.io"
      ];
      extra-trusted-public-keys = [
        "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      extra-experimental-features = [
        "flakes" # flakes
        "nix-command" # experimental nix commands
      ];
      trusted-users = [
        "root"
        username
      ];
      warn-dirty = false;
    };
  };
}
