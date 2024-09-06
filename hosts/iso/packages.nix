# which default packages to use for the system
{
  inputs,
  outputs,
  profile-config,
  pkgs,
  ...
}: let
  python-packages = ps:
    with ps; [
      pandas
      numpy
      opencv4
      ipython
    ];
in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # security audits
    signal-desktop
    nextcloud-client
    vlc
    thunderbird
    material-icons
    material-design-icons
    libreoffice
    gimp
    spotify
    okular
    ani-cli # The stable version is very outdated
  ];
}
