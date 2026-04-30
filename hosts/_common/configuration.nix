{
  lib,
  pkgs,
  self,
  config,
  ...
}: {
  # Run unpatched dynamic binaries on NixOS.
  programs.nix-ld = {
    enable = true;
    libraries = [pkgs.qt6.qtbase];
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  time.timeZone = lib.mkDefault "Europe/Zurich";
  i18n.defaultLocale = lib.mkDefault "en_GB.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = lib.mkDefault "us";
    variant = lib.mkDefault "";
  };

  # Allow ssh connections
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
    };
  };
  programs.ssh.startAgent = lib.mkDefault true;

  # Configure console keymap
  console.keyMap = lib.mkDefault "us";

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  programs.nix-index-database.comma.enable = true;

  age.identityPaths = lib.mkDefault ["/home/${config.modules.system.username}/.ssh/id_ed25519"];
  # See ../../modules
  modules = {
    system = {
      username = lib.mkDefault "kai";
      sshKey.enable = lib.mkDefault true;
      sshCA.enable = lib.mkDefault true;
    };

    programs = {
      git = {
        enable = lib.mkDefault true;
        userName = lib.mkDefault "Kai Berszin";
        userEmail = lib.mkDefault "mail@kaibersz.in";
        defaultBranch = lib.mkDefault "main";
        pullRebase = lib.mkDefault true;

        signing = {
          key = lib.mkDefault "~/.ssh/id_ed25519.pub";
          signByDefault = lib.mkDefault false;
          allowedKeys = let
            keys = import "${self}/secrets/ssh/user_keys.nix";
            masterKeys = import "${self}/secrets/ssh/master_keys.nix";
          in
            keys ++ masterKeys;
        };
      };

      nh = {
        enable = lib.mkDefault true;
        trustedSigningKeys = let keys = import "${self}/secrets/ssh/public_keys.nix"; in
          [
            keys."user-heartofgold"
            keys."user-silverwind"
          ];
      };
    };
  };
}
