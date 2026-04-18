{
  inputs,
  lib,
  pkgs,
  self,
  config,
  ...
}:
{
  # partly taken from github.com/bloxx12/nichts

  age.secrets.github-ro-token.file = "${self}/secrets/github-ro.age";

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
      warn-dirty = false;
    };
  };
}
