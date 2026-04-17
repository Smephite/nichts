{
  lib,
  pkgs,
  self,
  config,
  ...
}:
{

  age.secrets.github-ro-token.file = "${self}/secrets/github-ro.age";

  # Run unpatched dynamic binaries on NixOS.
  programs.nix-ld = {
    enable = true;
    libraries = [ pkgs.qt6.qtbase ];
  };

  nix = {
    extraOptions = ''
      !include ${config.age.secrets.github-ro-token.path}
    '';
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

  # See ../../modules
  modules = {
    system = {
      username = lib.mkDefault "kai";
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
          allowedKeys =
            let
              keys = import "${self}/secrets/public_keys.nix";
            in
            lib.mkDefault [
              keys.heartofgold-nix
              keys.silverwind-nix
            ];
        };

      };

      nh.enable = lib.mkDefault true;
    };
  };
}
