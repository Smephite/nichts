{pkgs, lib, config, ... }:
with lib; let
  cfg = config.modules.programs.i3;
  username = config.modules.other.system.username;
  mod = "Mod4";
in {
  options.modules.programs.i3.enable = mkEnableOption "i3";

  config = mkIf cfg.enable {
      services.xserver = {
          enable = true;
          xkb.layout =  "us";
      };
      xsession.windowManager.i3 = {
          enable = true;
          config = {
              modifier = mod;
              terminal = "alacritty";
              fonts ={
                 names = [ "JetBrains Mono" "pango:monospace"];
                 size = 12;
                 style = "Bold Semi-Condensed";
                };
              keybindings = lib.mkOptionDefault {
                  # Run stuff
                  "${mod}+d" = "exec --no-startup-id ${pkgs.dmenu}/bin/dmenu_run";
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
                  "XF86RaiseVolume" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && $refresh_i3status";
                  # Toggle stuff
                  "${mod}+f" = "fullscreen toggle";
              };
              window = {
                  titlebar = false;
                  border = 3;
                  hideEdgeBorders = true;
              };
              floating = {
                  titlebar = false;
              };
              bars = [
                  {
                  position = "bottom";
                  statusCommand = "${pkgs.i3status}/bin/i3status";
                  }
              ];
              startup ={
                command = [
                   

                ] + map(
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
                  }"
                  ''
                  ) monitors;
                      #"dex --autostart --environment i3";
                      #"nm-applet";
                      #"keepassxc";
              };
          };
      };
  };
}

