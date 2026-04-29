{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.atuin;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable or false;
    };
  };
}
