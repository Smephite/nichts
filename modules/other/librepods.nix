{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.librepods;
  username = config.modules.system.username;
in {
  options.modules.programs.librepods.enable = mkEnableOption "librepods";

  config = mkIf cfg.enable {
  #   assertions = [
  #   {
  #     assertion = builtins.hasAttr "programs.librepods" config;
  #     message = "Librepods is enabled but is missing from nixpkgs. This could be caused by librepods still being a PR and not being correctly installed!";
  #   }
  # ];

    programs =# mkIf (builtins.hasAttr "librepods" config.programs)
    {
      librepods = {
        enable = true;
      };
    };

    users.users.${username} = {
      extraGroups = ["librepods"];
    };
  };
}
