{
  config,
  lib,
  enabled,
  ...
}: let
  inherit (config.modules.system) username;
in {
  config = lib.mkIf enabled {
    modules.programs.firefox.extensions = [
    ];
  };
}
