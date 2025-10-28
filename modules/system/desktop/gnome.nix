{
  lib,
  config,
  pkgs,
  ...
}: let
  monitors = config.modules.system.desktop.monitors;
  gnomeCfg = config.modules.system.desktop.gnome;
in {
  options.modules.system.desktop.gnome = {
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

    environment.systemPackages = with pkgs; [ lm_sensors ]; # required by freon
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

    services.xserver.displayManager = lib.mkIf (!gnomeCfg.wayland && gnomeCfg.configureMonitors) {
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
        monitors;
    };
  };
}
