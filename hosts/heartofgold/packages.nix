# which default packages to use for the system
{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # inputs.vivado2019flake.vivado-2019_2

#    obsidian

    # security audits
#    lynis
#    baobab
    amdvlk
    signal-desktop
    nextcloud-client
    # etcher
    vlc
    thunderbird
    openjdk
    # pkgs.nordvpn # nur.repos.LuisChDev.nordvpn
    material-icons
    material-design-icons
    libreoffice
    gimp
    spotify
#    flameshot
#    feh
  ];
}