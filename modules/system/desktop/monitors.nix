{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;

  monitor_t = with types;
    submodule {
      options = {
        name = mkOption {
          type = str;
          description = "Give your monitor a cute name";
          default = "monitor0(I am lazy)";
        };
        device = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Connector name override (e.g. "DP-1"). When null (the default), the
            monitor is matched by its EDID description via {option}`model`.
          '';
        };
        model = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            EDID "Display Product Name" of the monitor (e.g. "DELL P2416D"),
            used by kanshi to match outputs.
          '';
        };
        serial = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Optional EDID "Display Product Serial Number" used to disambiguate
            multiple monitors of the same model.
          '';
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

  profile_t = with types;
    submodule {
      options = {
        groups = mkOption {
          type = listOf str;
          default = [];
          description = "Names of monitor groups to include in this profile.";
        };
        extra = mkOption {
          type = listOf monitor_t;
          default = [];
          description = "Additional monitors specific to this profile.";
        };
      };
    };

  cfg = config.modules.system.desktop;

  resolveProfile = profile:
    (lib.concatMap (g: cfg.monitorGroups.${g}) profile.groups) ++ profile.extra;
in {
  options.modules.system.desktop = {
    monitorGroups = mkOption {
      type = with types; attrsOf (listOf monitor_t);
      default = {};
      description = "Named reusable sets of monitors that can be composed into profiles.";
    };

    monitors = mkOption {
      type = with types; attrsOf profile_t;
      default = {};
      description = ''
        Named monitor profiles. Each profile references monitor groups and/or
        defines extra monitors. Kanshi selects the matching profile at runtime.
      '';
    };

    _resolvedMonitors = mkOption {
      type = with types; attrsOf (listOf monitor_t);
      internal = true;
      readOnly = true;
      description = "Flattened monitor lists per profile, resolved from groups + extra.";
    };
  };

  config = {
    modules.system.desktop._resolvedMonitors =
      lib.mapAttrs (_name: resolveProfile) cfg.monitors;

    assertions =
      # Every group referenced in a profile must exist
      lib.concatLists (lib.mapAttrsToList (
          profileName: profile:
            map (g: {
              assertion = cfg.monitorGroups ? ${g};
              message = "Monitor profile '${profileName}' references unknown group '${g}'";
            })
            profile.groups
        )
        cfg.monitors)
      ++
      # Every resolved monitor must have device or model
      lib.concatLists (lib.mapAttrsToList (
          profileName: monitors:
            lib.imap0 (i: m: {
              assertion = m.device != null || m.model != null;
              message = "Monitor profile '${profileName}' entry ${toString i} (${m.name}): either `device` or `model` must be set";
            })
            monitors
        )
        cfg._resolvedMonitors);
  };
}
