{
  pkgs,
  lib,
  self,
  config,
  ...
}: let
  user = "msc25h18";
  realHome = "/home/${user}";
in {

  imports = [
    ./packages.nix
    ../../modules/system/nix.nix
  ];

  home.username = user;
  home.homeDirectory = "${realHome}/nix-home";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nano";
  };

  programs.nix-index-database.comma.enable = true;

  modules.programs = {
    git = {
      enable = lib.mkDefault true;
      userName = lib.mkDefault "Kai Berszin";
      userEmail = lib.mkDefault "kberszin@ethz.ch";
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
    fish.enable = lib.mkDefault true;
    starship.enable = lib.mkDefault true;
    atuin.enable = lib.mkDefault true;
    nh = {
      enable = lib.mkDefault true;
      flakePath = lib.mkDefault "${config.home.homeDirectory}/repos/nichts";
    };

    #zed.enable = lib.mkDefault true;

    firefox = {
      enable = lib.mkDefault true;
      extensions = {
        "uBlock0@raymondhill.net" = {
          source = "ublock-origin"; # Ublock Origin
          private_browsing = true;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          source = "bitwarden-password-manager"; # Bitwarden
          private_browsing = true;
        };
        "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack" = "grammarly-1"; # Grammarly
        "zotero@chnm.gmu.edu" = "https://download.zotero.org/connector/firefox/release/Zotero_Connector-5.0.186.xpi"; # Zotero
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
    identityPaths = [ "${realHome}/.ssh/host_key" ];
  };

  # We need to manually execute the agenix service
  systemd.user.startServices = false;
  home.activation.agenixManual = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${builtins.head config.systemd.user.services.agenix.Service.ExecStart}
      '';


  nix.package = pkgs.nix;
  nix.settings = {
    use-sqlite-wal = false;
    fsync-metadata = false;
    sandbox = false;
#    max-jobs = lib.mkDefault 8;
#    cores = lib.mkDefault 0;
  };

  # XDG inside nix-home, isolated from host
  xdg.enable = true;
}
