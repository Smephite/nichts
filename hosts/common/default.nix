{nix}:
{
  imports = [
    ./authorized_keys.nix
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}