{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.modules.system.monitors;
  monitor_t = with types;
    submodule {
      options = {
        name = mkOption {
          type = str;
          description = "Give your monitor a cute name";
          default = "monitor0(I am lazy)";
        };
        device = mkOption {
          type = str;
          description = "The actual device name of the monitor";
        };
        resolution = mkOption {
          type = submodule {
            options = {
              x = mkOption {
                type = int;
                description = "monitor width";
                default = "1920";
              };
              y = mkOption {
                type = int;
                description = "monitor height";
                default = "1080";
              };
            };
          };
        };
        scale = mkOption {
          type = number;
          description = "monitor scale";
          default = 1.0;
        };
        refresh_rate = mkOption {
          type = float;
          description = "monitor refresh rate (in Hz)";
          default = 60;
        };
        position = mkOption {
          type = submodule {
            options = {
              x = mkOption {
                type = int;
                default = 0;
              };
              y = mkOption {
                type = int;
                default = 0;
              };
            };
          };

          description = "absolute monitor posititon";
          default = {
            x = 0;
            y = 0;
          };
        };
        transform = mkOption {
          type = ints.between 0 3;
          description = "Rotation of the monitor counterclockwise";
          default = 0;
        };
      };
    };
in {
  options.modules.system.monitors = {
    devices = lib.mkOption {
      description = "List of monitors to use";
      default = [];
      type = with lib.types; listOf monitor_t;
    };
    configureXserver = lib.mkEnableOption "configure xserver display manager";
  };

  config = {
    services.xserver.displayManager = lib.mkIf cfg.configureXserver {
      setupCommands =
        lib.strings.concatMapStrings (
          m: ''            xrandr --output "${m.device}" \
                                --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.x}" \
                                --rate "${builtins.toString m.refresh_rate}" \
                                --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
                                --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
                                --rotate "${
              if m.transform == 0
              then "normal"
              else if m.transform == 1
              then "left"
              else if m.transform == 2
              then "inverted"
              else if m.transform == 3
              then "right"
              else "normal"
            }\n"
          ''
        )
        cfg.devices;
    };
  };
}
