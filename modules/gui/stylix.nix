{ config, pkgs, lib, ... }:
with lib; let
    cfg = config.modules.programs.stylix;
    username = config.modules.other.system.username;
in {
    options.modules.programs.stylix.enable = mkEnableOption "stylix";

    config = mkIf cfg.enable {
        home-manager.users.${username} = {
            stylix = {
                targets = {
                    btop.enable = true;
                    fish.enable = true;
                    emacs.enable = true;
                    firefox.enable = true;
                    kitty.enable = true;
                    lazygit.enable = true;
                    rofi.enable = true;
                    tmux.enable = true;
                    vim.enable = true;
                    zathura.enable = true;
                    gtk.enable = true;
                    hyprland.enable = true;
                    waybar.enable = true;
                };
            };
        };
        stylix = {
            autoEnable = true;
            base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
            polarity = "dark";
            image = "${pkgs.catppuccin-wallpapers}/landscapes/Rainnight.jpg";
            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 24;
            };
            opacity = {
                applications = 0.7;
                popups = 0.7;
                terminal = 0.7;
                desktop = 0.7;
            };
            fonts = {
                sizes = {
                    terminal = 14;
                    popups = 14;

                };
                sansSerif = config.stylix.fonts.monospace;
                serif = config.stylix.fonts.monospace;
                emoji = config.stylix.fonts.monospace;
                monospace = {
                    package = (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];});
                    name = "JetBrains Mono Nerd Font";
                };
            };

        };
    };
}
