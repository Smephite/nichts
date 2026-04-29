{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.atuin;
  username = config.modules.system.username;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    home-manager.users.${username} = mkIf config.modules.other.home-manager.enable {
      imports = [./hm.nix];
      modules.programs.atuin = cfg;
    };
  };
}
