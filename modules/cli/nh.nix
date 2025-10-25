# blatantly stolen from github.com/bloxx12/nichts
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.programs.nh;
  gitPath = config.modules.system.gitPath;
  username = config.modules.system.username;
  etcPath = "nixconf";
in {
  options.modules.programs.nh.enable = mkEnableOption "nh";

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = gitPath;
    };
  };
}
