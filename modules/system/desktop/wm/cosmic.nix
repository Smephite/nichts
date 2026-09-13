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

    # Re-enable connected-but-disabled outputs after resume.
    # COSMIC sometimes fails to re-enable MST outputs after suspend.
    systemd.services."cosmic-randr-resume" = {
      description = "Trigger cosmic-randr output re-enable after resume";
      after = ["systemd-suspend.service" "systemd-hibernate.service"];
      wantedBy = ["systemd-suspend.service" "systemd-hibernate.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user --machine=${username}@ start cosmic-randr-reenable.service";
      };
    };

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
        systemd.user.services."cosmic-randr-reenable" = {
          Unit.Description = "Re-enable disabled COSMIC outputs";
          Service = {
            Type = "oneshot";
            ExecStart = let
              script = pkgs.writeShellScript "cosmic-randr-reenable" ''
                sleep 2
                ${pkgs.cosmic-randr}/bin/cosmic-randr list 2>/dev/null \
                  | ${pkgs.gnugrep}/bin/grep -oP '^\S+(?=\s+\(disabled\))' \
                  | while read -r output; do
                      echo "Re-enabling $output"
                      ${pkgs.cosmic-randr}/bin/cosmic-randr enable "$output"
                    done
                # Restart kanshi so it re-evaluates profiles with the newly enabled outputs
                /run/current-system/sw/bin/systemctl --user restart kanshi.service 2>/dev/null || true
              '';
            in "${script}";
          };
        };
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
