{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.nh;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = mkIf (cfg.flakePath != "") cfg.flakePath;
    };
  };
}
