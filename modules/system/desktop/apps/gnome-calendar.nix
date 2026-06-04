{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.desktop.apps.gnome-calendar;
in {
  options.modules.system.desktop.apps.gnome-calendar = {
    enable = lib.mkEnableOption "GNOME Calendar and its required background services";
  };

  config = lib.mkIf cfg.enable {
    # The application itself
    environment.systemPackages = with pkgs; [
      gnome-calendar
    ];

    # Required for GNOME apps to store settings/preferences
    programs.dconf.enable = true;

    services.gnome = {
      # The core backend that actually stores and fetches calendar events
      evolution-data-server.enable = true;

      # Required for syncing with Google, Nextcloud, or CalDAV providers
      gnome-online-accounts.enable = true;

      # Manages credentials and passwords for your online accounts
      gnome-keyring.enable = true;
    };

    # Ensure the keyring is unlocked on login (if using a display manager)
    services.pcscd.enable = true;
  };
}
