# which default packages to use for the system
{
  pkgs, 
  inputs,
  pkgs-unstable,
  ...
}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = (with pkgs; [
    # inputs.vivado2019flake.vivado-2019_2

    obsidian
    zotero

    # security audits
#    lynis
#    baobab
#    amdvlk
    wasistlos # whatsapp
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
    slack
    mattermost-desktop
    comma
    calc

    #quartus-prime-lite
    zoom-us

    #inputs.noctalia.packages.${system}.default
    discord
    # VPN

    openconnect
    networkmanager-openconnect
    teams-for-linux
    age-plugin-yubikey
    age
#    flameshot
#    feh
  ])
   ++
  (with pkgs-unstable; [
    signal-desktop
    yubioath-flutter
  ]);
}