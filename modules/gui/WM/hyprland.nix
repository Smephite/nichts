{ config, lib, pkgs, ... }: 

with lib;
let 
  cfg = config.modules.WM.hyprland;
  username = config.modules.other.system.username;
  monitors = config.modules.other.system.monitors;
in
{
  options.modules.WM.hyprland = {
    enable = mkEnableOption "hyprland";
    gnome-keyring.enable = mkEnableOption "gnome-keyring";
  };


  config = mkIf cfg.enable {

    services.displayManager = {
        sessionPackages = [ pkgs.hyprland ]; # pkgs.gnome.gnome-session.sessions ];
        defaultSession = "hyprland";
    };

    environment.systemPackages = with pkgs; [ xwayland ];

    programs.xwayland.enable = true;
    programs.hyprland = {
        enable = true;
    };

    services.gnome.gnome-keyring.enable = cfg.gnome-keyring.enable;
    security.pam.services.login.enableGnomeKeyring = cfg.gnome-keyring.enable;

    services.displayManager.sddm.wayland.enable = true;
    systemd.user.services.polkit-gnome-authentication-agent-1 = mkIf cfg.gnome-keyring.enable {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
      };
    };

    home-manager.users.${username} = {
      home.packages = with pkgs; [ 
        bluetuith
        brightnessctl
        # needed for wayland copy / paste support in neovim
        wl-clipboard
      ];


      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        xwayland.enable = true;
        settings = {
          exec-once = (if cfg.gnome-keyring.enable then 
            ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"]
          else []);
          monitor = map (
            m: "${m.device},${builtins.toString m.resolution.x}x${builtins.toString m.resolution.y}@${builtins.toString m.refresh_rate},${builtins.toString m.position.x}x${builtins.toString m.position.y},${builtins.toString m.scale},transform,${builtins.toString m.transform}"
          ) monitors; #TODO: default value
        };
      };
    };
  };
}
