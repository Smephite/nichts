# which default packages to use for the system
{pkgs, 
inputs,
...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # inputs.vivado2019flake.vivado-2019_2

    obsidian
    zotero

    # security audits
#    lynis
#    baobab
    amdvlk
    signal-desktop
    wasistlos # whatsapp
    nextcloud-client
    # etcher
    vlc
    thunderbird
    openjdk
    # pkgs.nordvpn # nur.repos.LuisChDev.nordvpn
    openconnect
    material-icons
    material-design-icons
    libreoffice
    gimp
    spotify
    slack
    mattermost-desktop
    comma
    calc

    quartus-prime-lite
    zoom-us


#    flameshot
#    feh
  ];
}