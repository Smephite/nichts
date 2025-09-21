{nix}:
{
  imports = [
    ./configuration.nix
    ./packages.nix
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}