{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.starship;
  username = config.modules.system.username;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.system.fonts.enable || config.modules.system.server;
        message = "modules.programs.starship requires modules.system.fonts to be enabled";
      }
    ];

    home-manager.users.${username} = mkIf config.modules.other.home-manager.enable {
      imports = [./hm.nix];
      modules.programs.starship.jj = config.modules.programs.jj.enable or false;
    };
  };
}
