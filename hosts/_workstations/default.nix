{
  imports = [
    ../_common/default.nix
    ./configuration.nix
    ./packages.nix
  ];

  # Workstations build as the logged-in user, who already has a GitHub key.
  modules.system.nichtsUnfree.enable = true;
}
