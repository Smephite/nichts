{
  lib,
  config,
  pkgs,
  ...
}: let
  monitors = config.modules.system.desktop.monitors;
  resolveOutput = config.modules.system.desktop._resolveOutput;
  gnomeCfg = config.modules.system.desktop.wm.gnome;

  xrandrTransform = t:
    if t == 1
    then "left"
    else if t == 2
    then "inverted"
    else if t == 3
    then "right"
    else "normal";

  mkXrandrMonitor = m: ''
    output=""
    ${
      if m.device != null
      then ''output=${lib.escapeShellArg m.device}''
      else ''
        output=$(${resolveOutput}/bin/monitor-resolve-output ${lib.escapeShellArg m.model} ${
          lib.optionalString (m.serial != null) (lib.escapeShellArg m.serial)
        } 2>/dev/null) || output=""
      ''
    }
    if [ -n "$output" ]; then
      ${pkgs.xorg.xrandr}/bin/xrandr --output "$output" \
        --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.y}" \
        --rate "${builtins.toString m.refresh_rate}" \
        --pos "${builtins.toString m.position.x}x${builtins.toString m.position.y}" \
        --rotate ${xrandrTransform m.transform} \
        || echo "monitor ${m.name}: xrandr failed" >&2
    else
      echo "monitor ${m.name}: no connector matched, skipping" >&2
    fi
  '';
in {
  options.modules.system.desktop.wm.gnome = {
    enable = lib.mkEnableOption "use gnome + gdm";
    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow GDM to run on Wayland instead of Xserver.
      '';
    };
    configureMonitors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically configure monitors.
      '';
    };
    xWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable xWayland
      '';
    };
  };
  config = lib.mkIf gnomeCfg.enable {
    # TODO: Split display and desktopmanager
    services.displayManager.gdm = {
      enable = true;
      wayland = gnomeCfg.wayland;
    };

    # Weird suspend loop, potentially only with nvidia power management
    # https://github.com/NixOS/nixpkgs/issues/336723
    # https://discourse.nixos.org/t/suspend-resume-cycling-on-system-resume/32322/9
    systemd = {
      services."gnome-suspend" = {
        description = "suspend gnome shell";
        before = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-suspend.service"
          "nvidia-hibernate.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.procps}/bin/pkill -f -STOP ${pkgs.gnome-shell}/bin/gnome-shell'';
        };
      };
      services."gnome-resume" = {
        description = "resume gnome shell";
        after = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-resume.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.procps}/bin/pkill -f -CONT ${pkgs.gnome-shell}/bin/gnome-shell'';
        };
      };
    };
    environment.systemPackages = with pkgs; [lm_sensors]; # required by freon
    services.desktopManager.gnome = {
      enable = true;
      sessionPath = with pkgs; [
        gnomeExtensions.pop-shell
        gnomeExtensions.xwayland-indicator
        gnomeExtensions.freon
      ];
    };

    programs.xwayland.enable = lib.mkDefault (gnomeCfg.wayland && gnomeCfg.xWayland);
    services.xserver.enable = true;

    programs.ssh.startAgent = lib.mkForce false;

    services.xserver.displayManager = lib.mkIf (!gnomeCfg.wayland && gnomeCfg.configureMonitors) {
      setupCommands = lib.concatMapStrings (m: "( ${mkXrandrMonitor m} ) || true\n") monitors;
    };
  };
}
