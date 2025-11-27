{
  lib,
  config,
  pkgs,
  ...
}: let
  monitors = config.modules.system.desktop.monitors;
  username = config.modules.system.username;
  niriCfg = config.modules.system.desktop.niri;
in {
  options.modules.system.desktop.niri = {
    enable = lib.mkEnableOption "use niri";
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
  config = lib.mkIf niriCfg.enable {
    # TODO: Split display and desktopmanager

    programs.regreet.enable = true;
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = '''';
        };
      };
    };

    programs.niri.enable = true;
    security.polkit.enable = true; # polkit
    services.gnome.gnome-keyring.enable = true; # secret service
    security.pam.services.swaylock = {};

    programs.waybar.enable = true; # top bar

    home-manager.users.${username} = {
      programs.alacritty.enable = true; # Super+T in the default setting (terminal)
      programs.fuzzel.enable = true; # Super+D in the default setting (app launcher)
      programs.swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
      programs.waybar.enable = true; # launch on startup in the default setting (bar)
      services.mako.enable = true; # notification daemon
      services.swayidle.enable = true; # idle management daemon
      services.polkit-gnome.enable = true; # polkit
      home.packages = with pkgs; [
        swaybg # wallpaper
        xwayland-satellite # xwayland support
      ];
    };
    

    programs.xwayland.enable = lib.mkDefault true;   
    services.xserver.enable = true;

  };
}
