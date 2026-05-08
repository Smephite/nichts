{
  lib,
  config,
  pkgs,
  ...
}: let
  monitors = config.modules.system.desktop.monitors;
  resolveOutput = config.modules.system.desktop._resolveOutput;
  cosmicCfg = config.modules.system.desktop.wm.cosmic;
  username = config.modules.system.username;

  cosmicTransform = t:
    if t == 1
    then "rotate90"
    else if t == 2
    then "rotate180"
    else if t == 3
    then "rotate270"
    else "normal";

  mkCosmicMonitor = m: ''
    output=""
    ${
      if m.device != null
      then ''output=${lib.escapeShellArg m.device}''
      else ''
        output=$(${resolveOutput}/bin/monitor-resolve-output ${lib.escapeShellArg m.model} ${
          lib.optionalString (m.serial != null) (lib.escapeShellArg m.serial)
        }) || true
      ''
    }
    if [[ -z "$output" ]]; then
      echo "monitor ${m.name}: no connector matched, skipping" >&2
    else
      ${pkgs.cosmic-randr}/bin/cosmic-randr mode \
        --refresh ${builtins.toString m.refresh_rate} \
        --pos-x ${builtins.toString m.position.x} \
        --pos-y ${builtins.toString m.position.y} \
        --scale ${builtins.toString m.scale} \
        --transform ${cosmicTransform m.transform} \
        "$output" ${builtins.toString m.resolution.x} ${builtins.toString m.resolution.y} \
        || echo "monitor ${m.name}: cosmic-randr failed" >&2
    fi
  '';
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

    systemd.user.services.cosmic-randr-setup = lib.mkIf cosmicCfg.configureMonitors {
      description = "Configure monitors via cosmic-randr";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cosmic-randr-setup" ''
          set -u
          ${lib.concatMapStrings (m: "( ${mkCosmicMonitor m} ) || true\n") monitors}
        '';
      };
    };
  };
}
