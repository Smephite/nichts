{
  inputs,
  outputs,
  pkgs,
  profile-config,
  ...
}: let
  # nur-no-pkgs = import inputs.nur-no-pkgs { pkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; nurpkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; };
  python-packages = ps:
    with ps; [
      pandas
      numpy
      opencv4
      ipython
      # bt-dualboot for synching up bluetooth between Windows and Linux
      (
        buildPythonPackage rec {
          pname = "bt-dualboot";
          version = "1.0.1";
          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-pjzGvLkotQllzyrnxqDIjGlpBOvUPkWpv0eooCUrgv8=";
          };
          doCheck = false;
          propagatedBuildInputs = [
            pkgs.chntpw
          ];
        }
      )
    ];
in {
  imports = [
    # nur-no-pkgs.repos.LuisChDev.modules.nordvpn
    # ../../modules/programs/java.nix
  ];

  #  services.nordvpn.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-24.8.6" # NEEDED for Webcord
    "electron-19.1.9"
  ];

  environment.systemPackages = with pkgs; [
    jetbrains.idea-community
    steam
    discord
    ani-cli
    okular
    texliveFull
    android-tools
    betterdiscordctl
    signal-desktop
    nextcloud-client
    (python3.withPackages python-packages)
    vlc
    audacity
    thunderbird
    eclipses.eclipse-java
    openjdk
    gnomeExtensions.forge # Window manager
    gnomeExtensions.disable-unredirect-fullscreen-windows
    gnomeExtensions.appindicator
    gnomeExtensions.auto-move-windows
    gnomeExtensions.removable-drive-menu
    # pkgs.nordvpn # nur.repos.LuisChDev.nordvpn
    # openvpn # used by nordvpn because NordLynx crashes gnome when used in the gnome-extension
    # unstable.gnomeExtensions.gnordvpn-local
    # gnomeExtensions.pop-shell
    gnomeExtensions.unite # remove window decoration
    material-icons
    material-design-icons
    libreoffice
    spotify
    # minecraft
    prismlauncher
    # window manager
    hyprland
    hyprland-protocols
    flameshot
    feh
    gamescope
    xorg.xrandr # see configuration.nix: needed for xwayland applications to start on right monitor
    teamspeak_client
    wine
  ];
}
