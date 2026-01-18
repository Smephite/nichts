{
  lib,
  config,
  pkgs,
  ...
}: let
  monitors = config.modules.system.desktop.monitors;
  cosmicCfg = config.modules.system.desktop.wm.cosmic;
in {
  options.modules.system.desktop.wm.cosmic = {
    enable = lib.mkEnableOption "use cosmic + cosmic greeter";
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
  config = lib.mkIf cosmicCfg.enable {
   


    # Enable the COSMIC login + desktop env
    services.desktopManager.cosmic.enable = true;
#    services.desktopManager.plasma6.enable = true; # Fallback


    services.system76-scheduler.enable = true;
    
    # Xserver support
    programs.xwayland.enable = lib.mkDefault cosmicCfg.xWayland;   
    services.xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
    };
    services.desktopManager.cosmic.xwayland.enable = lib.mkDefault cosmicCfg.xWayland;


    programs.ssh.startAgent = lib.mkForce false;

#    services.xserver.displayManager = lib.mkIf (!gnomeCfg.wayland && gnomeCfg.configureMonitors) {
#      setupCommands =
#        lib.strings.concatMapStrings (
#          m: ''            xrandr --output "${m.device}" \
#                                --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.x}" \
#                                --rate "${builtins.toString m.refresh_rate}" \
#                                --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
#                                --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
#                                --rotate "${
#              if m.transform == 0
#              then "normal"
#              else if m.transform == 1
#              then "left"
#              else if m.transform == 2
#              then "inverted"
#              else if m.transform == 3
#              then "right"
#              else "normal"
#            }\n"
#          ''
#        )
#        monitors;
#    };
  };
}
