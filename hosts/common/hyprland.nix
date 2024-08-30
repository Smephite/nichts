{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  username = config.modules.other.system.username;
  cfg = config.modules.WM.hyprland;

  variant = "mocha";

  hyprland-catppuccin = pkgs.stdenv.mkDerivation {
    name = "hyprland-catppuccin";
    version = "b57375545f5da1f7790341905d1049b1873a8bb3v";
    runtimeInputs = with pkgs; [];
    src = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "hyprland";
      rev = "b57375545f5da1f7790341905d1049b1873a8bb3";
      hash = "sha256-XTqpmucOeHUgSpXQ0XzbggBFW+ZloRD/3mFhI+Tq4O8=";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p $out

      cp -r "$src"/themes "$out"


      runHook postInstall
    '';
  };

  hyprlock-cat = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png";
    hash = "sha256-A85wBdJ2StkgODmxtNGfbNq8PU3G3kqnBAwWvQXVtqo=";
  };

  hyprlock-catppuccin = pkgs.stdenv.mkDerivation {
    name = "hyprlock-catppuccin";
    version = "0.0";
    runtimeInputs = [hyprland-catppuccin];
    src = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "hyprlock";
      rev = "d5a6767000409334be8413f19bfd1cf5b6bb5cc6";
      hash = "sha256-pjMFPaonq3h3e9fvifCneZ8oxxb1sufFQd7hsFe6/i4=";
    };
    installPhase = ''
      runHook preInstall
      dir="$out/.config/hypr"

      mkdir -p "$dir"

      cp $src/hyprlock.conf $dir/hyprlock.conf
      sed -i -e "s~\$HOME/\.config/hypr/mocha.conf~$dir/${variant}.conf~g" "$dir/hyprlock.conf"
      sed -i -e "s~\~/.config/background~${pkgs.catppuccin-wallpapers}/mandelbrot/mandelbrot_full_flamingo.png~g" "$dir/hyprlock.conf"
      sed -i -e "s~\~/.face~${hyprlock-cat}~g" "$dir/hyprlock.conf"
      # sed -i -e "s~\~/.face~/tmp/hyprlock.png~g" "$dir/hyprlock.conf"
      cp "${hyprland-catppuccin}/themes/${variant}.conf" "$dir/${variant}.conf"

      runHook postInstall
    '';
  };
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rofi-wayland
      waybar
      hyprlock
      hyprland
      hyprshade
      lxqt.lxqt-openssh-askpass
      libdrm

      dunst
      # wireplumber
      pciutils # lspci is needed by hyprland
      bluez
      dunst
      swww
      sway-contrib.grimshot
    ];

    services.logind.lidSwitch = "suspend";
    # hyprland settings
    home-manager.users.${username} = {
      xdg.configFile."hypr/hyprlock.conf".source = "${hyprlock-catppuccin}/.config/hypr/hyprlock.conf";
      # xdg.configFile."background".source = "${pkgs.catppuccin-wallpapers}/mandelbrot/mandelbrot_gap_pink.png";
      # xdg.configFile."hypr/${variant}.conf".source = "${hyprlock-catppuccin}/.config/hypr/${variant}.conf";

      services.hypridle = {
        enable = true;
        settings = {
          before_sleep_cmd = "hyprlock";
        };
      };

      programs.waybar.enable = true;
    };
  };
}
