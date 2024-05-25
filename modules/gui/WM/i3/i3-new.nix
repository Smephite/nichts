{pkgs, lib, config, ... }:
with lib; let
  cfg = config.modules.programs.i3;
  username = config.modules.other.system.username;
  monitors = config.modules.other.system.monitors;
  mod = "Mod4";
in {
  options.modules.programs.i3.enable = mkEnableOption "i3";

  config = mkIf cfg.enable {
    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "gtk";
    }; 

      environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 

      # services.xserver = {
      #     enable = true;
      #     xkb.layout =  "us"; 
      # };
      services.xserver.enable  =  true;
      services.displayManager = {
        sddm.enable = true;
        defaultSession = "none+i3";
      };
      services.xserver.desktopManager.xterm.enable = false;
      services.xserver.displayManager = {
        setupCommands = lib.strings.concatMapStrings (
          m: ''xrandr --output "${m.device}" \
          --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.x}" \
          --rate "${builtins.toString m.refresh_rate}" \
          --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
          --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
          --rotate "${
            if m.transform == 0 then
              "normal"
            else if m.transform == 1 then
              "left"
            else if m.transform == 2 then
              "inverted"
            else if m.transform == 3 then
              "right"
            else
              "normal"
          }\n"
          ''
        ) monitors;
      };
      services.xserver.windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu #application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
        ];
      };

      environment.systemPackages = with pkgs; [ 
        feh
        brightnessctl
        rofi 
        alacritty 
      ];
      home-manager.users.${username} = {
          xsession.enable = true;
          xsession.windowManager.i3 = {
              enable = true;
              config = {
                  modifier = mod;
                  terminal = "alacritty";
                  fonts ={
                    names = [ "JetBrains Mono" "pango:monospace"];
                    size = 12.0;
                    style = "Bold Semi-Condensed";
                    };
                  keybindings = {
                      # Run stuff
                      "${mod}+Shift+Return" = "exec --no-startup-id rofi -show drun";
                      "${mod}+Return" = "exec --no-startup-id alacritty";
                      "${mod}+Shift+q" = "kill";
                      # Focus
                      "${mod}+h" = "focus left";
                      "${mod}+j" = "focus down";
                      "${mod}+k" = "focus up";
                      "${mod}+l" = "focus right";
                      # Move
                      "${mod}+Shift+h" = "move left";
                      "${mod}+Shift+j" = "move down";
                      "${mod}+Shift+k" = "move up";
                      "${mod}+Shift+l" = "move right";
                      "XF86MonBrightnessUp" = "exec brightnessctl set 10%+ && $refresh_i3status";
                      "XF86MonBrightnessDown" = "exec brightnessctl set 10%- && $refresh_i3status";
                      #Example volume button that allows press and hold, volume limited to 150%"
                      "XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && $refresh_i3status";
                      #Example volume button that will activate even while an input inhibitor is active"
                      "XF86AudioLowerVolume" = "exec wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%- && $refresh_i3status";
                      "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && $refresh_i3status";
                      "${mod}+b" = "exec alacritty --title bluetuith -e bluetuith";
                      "${mod}+a" = "exec ${pkgs.ani-cli-advanced}/bin/ani-cli-advanced";
                      "${mod}+SHIFT+a" = "exec ani-cli --rofi -c";
                      "${mod}+f" = "fullscreen toggle";
                  };
                  window = {
                      titlebar = false;
                      border = 3;
                      hideEdgeBorders = "smart";
                  };
                  floating = {
                      titlebar = false;
                  };
                  bars = [
                      {
                      position = "top";
                      statusCommand = "${pkgs.i3status}/bin/i3status";
                      }
                  ];
                  startup = [
                  ] ++ builtins.map  (
                    m: 
                    { 
                      always  = true;
                      command = ''xrandr --output "${m.device}" \
                      --mode "${builtins.toString m.resolution.x}x${builtins.toString m.resolution.x}" \
                      --rate "${builtins.toString m.refresh_rate}" \
                      --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
                      --pos  "${builtins.toString m.position.x}x${builtins.toString m.position.x}" \
                      --rotate "${
                        if m.transform == 0 then
                          "normal"
                        else if m.transform == 1 then
                          "left"
                        else if m.transform == 2 then
                          "inverted"
                        else if m.transform == 3 then
                          "right"
                        else
                          "normal" 
                      }"
                      '';
                    }
                  ) monitors;
              };
          };
      };
  };
}

