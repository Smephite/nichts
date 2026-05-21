{
  lib,
  self,
  config,
  ...
}: let
  user = "kberszin";
  realHome = "/home/${user}";
in {
  imports = [
    ../_common
    ./packages.nix
    ../../modules/system/nix.nix
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

      signing = {
        key = lib.mkDefault "~/.ssh/id_ed25519.pub";
        signByDefault = lib.mkDefault true;
        allowedKeys = let
          keys = import "${self}/secrets/ssh/user_keys.nix";
          masterKeys = import "${self}/secrets/ssh/master_keys.nix";
        in
          keys ++ masterKeys;
      };
    };
    nh.flakePath = lib.mkDefault "${config.home.homeDirectory}/repos/nichts";

    #zed.enable = lib.mkDefault true;

    firefox = {
      enable = lib.mkDefault true;
      extensions = {
        "uBlock0@raymondhill.net" = {
          source = "ublock-origin";
          private_browsing = true;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          source = "bitwarden-password-manager";
          private_browsing = true;
        };
        "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack" = "grammarly-1";
        "zotero@chnm.gmu.edu" = "https://download.zotero.org/connector/firefox/release/Zotero_Connector-5.0.186.xpi";
      };
    };
  };

  modules.system.sshKey = {
    enable = true;
    hostname = "ethz";
  };

  age = {
    secretsDir = "${config.home.homeDirectory}/.local/share/agenix/agenix";
    secretsMountPoint = "${config.home.homeDirectory}/.local/share/agenix/agenix.d";
    identityPaths = ["${realHome}/.ssh/host_key"];
  };

  home.activation.agenixManual = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${builtins.head config.systemd.user.services.agenix.Service.ExecStart}
  '';
}
