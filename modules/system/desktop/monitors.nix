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
        manufacturer = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            EDID manufacturer name (e.g. "BOE", "HP Inc."). Used together with
            model and serial for kanshi output matching.
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
        internalMonitorOverrides = mkOption {
          type = attrs;
          default = {};
          description = "Attribute overrides applied to the internal monitor for this profile (e.g. refresh_rate, position).";
        };
      };
    };

  cfg = config.modules.system.desktop;

  # Resolve a catalog entry name with overrides into a monitor_t value
  resolveCatalogEntry = name: overrides:
    cfg.monitorCatalog.${name} // overrides;

  # Resolve a group (attrset of catalog-name -> overrides) into a list of monitors
  resolveGroup = groupName:
    lib.mapAttrsToList (name: overrides: resolveCatalogEntry name overrides)
    cfg.monitorGroups.${groupName};

  # Resolve internal monitor — string means catalog lookup, attrset means inline
  resolvedInternal =
    if cfg.internalMonitor == null
    then null
    else if builtins.isString cfg.internalMonitor
    then cfg.monitorCatalog.${cfg.internalMonitor}
    else cfg.internalMonitor;

  hasInternal = resolvedInternal != null;

  resolveExternals = profile:
    (lib.concatMap resolveGroup profile.groups) ++ profile.extra;

  applyOverrides = overrides:
    resolvedInternal // overrides;

  resolvedProfiles =
    if hasInternal
    then
      (lib.concatMapAttrs (name: profile: {
          ${name} = resolveExternals profile ++ [(applyOverrides profile.internalMonitorOverrides)];
          "${name}-clamshell" = resolveExternals profile;
        })
        cfg.monitors)
      // {undocked = [resolvedInternal];}
    else lib.mapAttrs (_name: resolveExternals) cfg.monitors;
in {
  options.modules.system.desktop = {
    monitorCatalog = mkOption {
      type = with types; attrsOf monitor_t;
      default = {};
      description = "Named monitor definitions. Referenced by monitorGroups and internalMonitor.";
    };

    internalMonitor = mkOption {
      type = with types; nullOr (either str monitor_t);
      default = null;
      description = ''
        The built-in display (e.g. laptop panel). Can be a catalog name (string)
        or an inline monitor definition. When set, each monitor profile
        automatically generates a clamshell variant (without internal) and an
        undocked profile (internal only).
      '';
    };

    monitorGroups = mkOption {
      type = with types; attrsOf (attrsOf attrs);
      default = {};
      description = ''
        Named groups of monitors. Each group is an attrset mapping catalog entry
        names to override attrs (e.g. position, scale, transform).
      '';
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
      description = "Flattened monitor lists per profile, resolved from catalog + groups + extra.";
    };
  };

  config = {
    modules.system.desktop._resolvedMonitors = resolvedProfiles;

    assertions =
      # Every catalog entry referenced in a group must exist
      lib.concatLists (lib.mapAttrsToList (
          groupName: entries:
            lib.mapAttrsToList (entryName: _: {
              assertion = cfg.monitorCatalog ? ${entryName};
              message = "Monitor group '${groupName}' references unknown catalog entry '${entryName}'";
            })
            entries
        )
        cfg.monitorGroups)
      ++
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
      # If internalMonitor is a string, it must exist in catalog
      lib.optional (cfg.internalMonitor != null && builtins.isString cfg.internalMonitor) {
        assertion = cfg.monitorCatalog ? ${cfg.internalMonitor};
        message = "internalMonitor '${cfg.internalMonitor}' not found in monitorCatalog";
      }
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
        cfg._resolvedMonitors)
      ++
      # Don't manually define 'undocked' when internalMonitor is set
      lib.optional (hasInternal && cfg.monitors ? undocked) {
        assertion = false;
        message = "Do not define an 'undocked' monitor profile when internalMonitor is set — it is auto-generated.";
      };
  };
}
