{
  lib,
  pkgs,
  config,
  self,
  ...
}: let
  username = config.modules.system.username;
in {
  age.secrets.uni-vpn = {
    file = self + "/secrets/uni.vpn.age";
    owner = config.modules.system.username;
  };

  boot.loader.systemd-boot.configurationLimit = 20;

  security.sudo = {
    package = pkgs.sudo.override {withInsults = true;};
    wheelNeedsPassword = true;
  };

  programs.ssh.enableAskPassword = true;

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
  # printer autodiscovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  # be nice to your ssds
  services.fstrim.enable = true;

  # Programs
  programs = {
    gnupg.agent = {
      enable = true;
    };
    claude-desktop = {
      enable = true;
      fhs = true;
      claudeCodePackage = pkgs.claude-code;
    };
  };

  # ../../modules
  modules = {
    programs = {
      fish.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
      atuin.enable = lib.mkDefault true;

      ausweisapp.enable = lib.mkDefault true;
      #zed.enable = lib.mkDefault true;

      git.signing.signByDefault = lib.mkOverride 900 true;

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
        openconnect = {
          enable = lib.mkDefault true;
          scripts.profiles.ethz.file = config.age.secrets.uni-vpn.path;
        };
      };

      gitPath = lib.mkDefault "/home/${config.modules.system.username}/repos/nichts";

      desktop = {
        windowManager = lib.mkDefault "gnome";
        monitorGroups.desk-externals = [
          {
            name = "Dell";
            model = "DELL P2416D";
            resolution = {
              x = 2560;
              y = 1440;
            };
            scale = 1.2356;
            refresh_rate = 59.951;
            position = {
              x = 0;
              y = 365;
            };
          }
          {
            name = "Gigabyte";
            model = "M34WQ";
            resolution = {
              x = 3440;
              y = 1440;
            };
            scale = 1.1;
            refresh_rate = 59.973;
            position = {
              x = 2072;
              y = 293;
            };
          }
          {
            name = "BenQ";
            model = "BenQ GL2450";
            resolution = {
              x = 1920;
              y = 1080;
            };
            scale = 0.9267;
            refresh_rate = 60.0;
            position = {
              x = 5199;
              y = 0;
            };
            transform = 1;
          }
        ];
      };
    };

    other.home-manager = {
      enable = lib.mkDefault true;
      enableDirenv = lib.mkDefault true;
    };

    services = {
      pipewire.enable = lib.mkDefault true;
      attic-push.enable = lib.mkDefault true;
    };
  };
}
