{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.zed;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    home.packages = mkIf cfg.withPackage [pkgs.zed-editor];
    xdg.configFile."zed/settings.json".source = ./settings.json;
  };
}
