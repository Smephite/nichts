{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (inputs) cosmic-manager;
  cosmicCfg = config.modules.system.desktop.wm.cosmic;
  username = config.modules.system.username;
in {
  options.modules.system.desktop.wm.cosmic = {
    enable = lib.mkEnableOption "use cosmic + cosmic greeter";
    xWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable xWayland
      '';
    };
  };
  config = lib.mkIf cosmicCfg.enable {
    # Workaround for display artifacts with AMD iGPU + external monitors
    # https://github.com/pop-os/cosmic-comp/issues/2336
    environment.variables.COSMIC_DISABLE_DIRECT_SCANOUT = "y";

    # Enable the COSMIC login + desktop env
    services.desktopManager.cosmic.enable = true;
    #    services.displayManager.cosmic-greeter.enable = true;
    #    services.desktopManager.plasma6.enable = true; # Fallback
    services.displayManager.cosmic-greeter.enable = false;

    services.greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${pkgs.cosmic-session}/bin/start-cosmic";
          user = "greeter";
        };
      };
    };

    services.system76-scheduler.enable = true;

    # Xserver support
    programs.xwayland.enable = lib.mkDefault cosmicCfg.xWayland;
    services.xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
    };
    services.desktopManager.cosmic.xwayland.enable = lib.mkDefault cosmicCfg.xWayland;

    environment.systemPackages = with pkgs; [
      cosmic-session
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-cosmic];
    };
    #    environment.pathsToLink = [ "/share/wayland-sessions" ];

    #   users.users.${username}.extraGroups = [ "shared" "video" "render"];
    #   users.users.cosmic-greeter.extraGroups = [ "video" "render"];

    programs.ssh.startAgent = lib.mkForce false;

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd = {
      enableGnomeKeyring = true;
      fprintAuth = true;
    };
    #    boot.blacklistedKernelModules = [ "simpledrm" ];

    home-manager = {
      sharedModules = [cosmic-manager.homeManagerModules.cosmic-manager];
      users.${username} = {
        wayland.desktopManager.cosmic.enable = true;
        programs.cosmic-term = {
          enable = true;
          settings = {
            font_name = "JetBrainsMonoNL Nerd Font Mono";
            font_size = 14;
            use_bright_bold = false;
          };
          profiles = [
            {
              name = "Default";
              command = "fish";
              hold = false;
              is_default = true;
              syntax_theme_dark = "COSMIC Dark";
              syntax_theme_light = "COSMIC Light";
            }
          ];
        };
      };
    };
  };
}
