{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.zed;
  username = config.modules.system.username;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.zed-editor];

    home-manager.users.${username} = mkIf config.modules.other.home-manager.enable {
      imports = [./hm.nix];
      modules.programs.zed = cfg // {withPackage = false;};
    };
  };
}
