{
  inputs,
  config,
  lib,
  ...
}:
with lib;
  let
    username = config.modules.system.username;
    cfg = config.modules.programs.bender;

    system = "x86_64-linux";

    bender = inputs.bender.packages.${system}.default;
  in {
    options.modules.programs.bender = {
      enable = mkEnableOption "bender";
    };

    config = mkIf cfg.enable {
      home-manager.users.${username} = {
        home.packages = with pkgs; [bender];
      };
    };
  }
