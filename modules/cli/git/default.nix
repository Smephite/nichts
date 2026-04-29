{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.git;
  username = config.modules.system.username;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    home-manager.users.${username} = mkIf config.modules.other.home-manager.enable {
      imports = [./hm.nix];
    };

    programs.git = mkIf (!config.modules.other.home-manager.enable) {
      enable = true;
    };
  };
}
