{
  lib,
  config,
  pkgs,
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
            connector is resolved at runtime from the monitor's EDID via
            {option}`model` and optional {option}`serial`.
          '';
        };
        model = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            EDID "Display Product Name" of the monitor (e.g. "DELL P2416D"),
            used to look up the live DRM connector when {option}`device` is
            not set.
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

  resolveOutput = pkgs.writeShellApplication {
    name = "monitor-resolve-output";
    runtimeInputs = with pkgs; [edid-decode coreutils gnused];
    text = ''
      # usage: monitor-resolve-output <model> [serial]
      # prints the DRM connector name (e.g. DP-1) on stdout, or exits non-zero.
      model="''${1:-}"
      serial="''${2:-}"
      if [[ -z "$model" ]]; then
        echo "monitor-resolve-output: model is required" >&2
        exit 2
      fi
      shopt -s nullglob
      for edid in /sys/class/drm/card*-*/edid; do
        # /sys files report stat size 0; check actual byte count
        bytes=$(wc -c < "$edid")
        [[ "$bytes" -gt 0 ]] || continue
        info=$(edid-decode "$edid" 2>/dev/null) || continue
        edid_model=$(printf '%s\n' "$info" | sed -nE "s/^[[:space:]]*Display Product Name: '(.*)'[[:space:]]*$/\1/p" | head -1)
        [[ "$edid_model" == "$model" ]] || continue
        if [[ -n "$serial" ]]; then
          edid_serial=$(printf '%s\n' "$info" | sed -nE "s/^[[:space:]]*Display Product Serial Number: '(.*)'[[:space:]]*$/\1/p" | head -1)
          [[ "$edid_serial" == "$serial" ]] || continue
        fi
        # /sys/class/drm/cardN-DP-1/edid -> DP-1
        path=''${edid%/edid}
        base=''${path##*/}
        connector=''${base#*-}
        printf '%s\n' "$connector"
        exit 0
      done
      echo "monitor-resolve-output: no connector matched model='$model' serial='$serial'" >&2
      exit 1
    '';
  };
in {
  options.modules.system.desktop = {
    monitors = lib.mkOption {
      description = "List of monitors to use";
      default = [];
      type = with lib.types; listOf monitor_t;
    };
    _resolveOutput = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      description = "Helper script that resolves a monitor's EDID model/serial to the live DRM connector name.";
    };
  };

  config = {
    modules.system.desktop._resolveOutput = resolveOutput;
    assertions =
      lib.imap0 (i: m: {
        assertion = m.device != null || m.model != null;
        message = "modules.system.desktop.monitors[${toString i}] (${m.name}): either `device` or `model` must be set";
      })
      config.modules.system.desktop.monitors;
  };
}
