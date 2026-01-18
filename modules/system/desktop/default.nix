{
  config,
  lib,
  ...
}: let
  cfg = config.modules.system.desktop;

  wmDir = ./wm;
  files = builtins.readDir wmDir;
  nixFiles = builtins.filter (x: lib.hasSuffix ".nix" x) (builtins.attrNames files);
  wmNames = map (name: lib.removeSuffix ".nix" name) nixFiles;

#  dmDir = ./dm;
#  dmFiles = builtins.readDir dmDir;
#  nixDmFiles = builtins.filter (x: lib.hasSuffix ".nix" x) (builtins.attrNames dmFiles);
#  dmNames = map (name: lib.removeSuffix ".nix" name) nixDmFiles;

#  dmConfig = config.modules.system.desktop.dm or {};
#  enabledDms = lib.filterAttrs (name: module: module.enable or false) dmConfig;
#  enabledDmNames = lib.attrNames enabledDms;

  wmConfig = config.modules.system.desktop.wm or {};
  enabledWms = lib.filterAttrs (name: module: module.enable or false) wmConfig;
  enabledWmNames = lib.attrNames enabledWms;
in {
  imports =
    [
      ./monitors.nix
    ]
    ++ (map (name: wmDir + "/${name}" ) nixFiles)
#    ++ (map (name: dmDir + "/${name}" ) nixDmFiles)
    ;

  options.modules.system.desktop = {
    windowManager = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum wmNames);
      default = null;
      description = "The window manager/desktop environment to use.";
    };

#    displayManager = lib.mkOption {
#      type = lib.types.nullOr (lib.types.enum dmNames);
#      default = null;
#      description = "The display manager to use.";
#    };
  };
  config = lib.mkMerge [
    
    (lib.mkIf (cfg.windowManager != null) {
      modules.system.desktop.wm.${cfg.windowManager}.enable = true;
    })

#    (lib.mkIf (cfg.displayManager != null) {
#      modules.system.desktop.dm.${cfg.displayManager}.enable = true;
#    })

#    {
#      assertions = [
#        {
#          assertion = builtins.length enabledDmNames <= 1;
#          message = "Multiple Display Managers enabled: ${toString enabledDmNames}";
#        }
#      ];
#
#      warnings =
#        lib.optional (builtins.length enabledWmNames > 1)
#          "Warning: Multiple Window Managers are enabled (${toString enabledWmNames})."
#        ++
#        lib.optional (builtins.length enabledWmNames == 0 && builtins.length enabledDmNames == 1)
#          "Warning: No Window Manager enabled, but Display Manager (${toString enabledDmNames}) is."
#        ++
#        lib.optional (builtins.length enabledWmNames > 0 && builtins.length enabledDmNames == 0)
#          "Warning: Window Manager enabled but no Display Manager.";
#    }
  ];
}
