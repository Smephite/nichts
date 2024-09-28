# which default packages to use for the system
{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # inputs.vivado2019flake.vivado-2019_2
    mars-mips

    obsidian

    # security audits
    lynis
    jetbrains.idea-community
    jetbrains.rust-rover
    baobab
    amdvlk
    texlive.combined.scheme-full
    android-tools
    signal-desktop
    nextcloud-client
    # etcher
    vlc
    audacity
    thunderbird
    eclipses.eclipse-java
    openjdk
    # pkgs.nordvpn # nur.repos.LuisChDev.nordvpn
    material-icons
    material-design-icons
    libreoffice
    gimp
    spotify
    flameshot
    feh
    # Animeeeeee!
    ani-cli # The stable version is very outdated
    superTuxKart
    nnn
  ];
}
