{lib, ...}: {
  # Run unpatched dynamic binaries on NixOS.
  programs.nix-ld.enable = true;


  nix.settings.experimental-features = ["nix-command" "flakes"];

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
  programs.ssh.startAgent = true;
  
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
      };

      nh.enable = lib.mkDefault true;
    };
  };
}
