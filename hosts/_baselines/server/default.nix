# Baseline server configuration
# Copy this directory as a starting point for new server hosts.
#
# Customize:
#   - Set networking.hostName in configuration.nix
#   - Adjust disk-config.nix for the target disk layout
#   - Update hardware-configuration.nix (run nixos-generate-config --show-hardware-config on target)
#   - In the new host's default.nix, add `inputs.disko.nixosModules.disko` to imports
{
  imports = [
    ../_servers
    ./configuration.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];
}
