{
  lib,
  pkgs,
  config,
  ...
}: let
  username = config.modules.system.username;
in {

  boot.loader.systemd-boot.configurationLimit = 20;

  security.sudo = {
    package = pkgs.sudo.override {withInsults = true;};
    wheelNeedsPassword = true;
  };


  age.identityPaths = lib.mkDefault ["/home/${config.modules.system.username}/.ssh/id_ed25519"];

  networking.dhcpcd.wait = "background";

  home-manager.backupFileExtension = "bak";
  users.users.${username}.uid = 1000;

  # Services
  services.locate = {
    enable = true;
    interval = "hourly";
    package = pkgs.plocate;
  };
  services.udev.packages = [pkgs.yubikey-personalization];
  services.pcscd.enable = true;
  services.envfs.enable = true;
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  # be nice to your ssds
  services.fstrim.enable = true;

  # Programs
  programs.gnupg.agent = {
    enable = true;
  };

  # ../../modules
  modules = {
    programs = {
      fish.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
      atuin.enable = lib.mkDefault true;

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

    system = {
      fonts.enable = lib.mkDefault true;
      network = {
        enable = lib.mkDefault true;
        openconnect.enable = lib.mkDefault true;
      };

      gitPath = lib.mkDefault "/home/${config.modules.system.username}/repos/nichts";

      desktop = {
        gnome.enable = lib.mkDefault true;
      };
    };

    other.home-manager = {
      enable = lib.mkDefault true;
      enableDirenv = lib.mkDefault true;
    };

    services = {
      pipewire.enable = lib.mkDefault true;
    };
  };
}
