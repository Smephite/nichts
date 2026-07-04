{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.modules.system.fingerprint;
in {
  options.modules.system.fingerprint = {
    enable = lib.mkEnableOption "fingerprint authentication";
    disableOnLidClose = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable fingerprint when the laptop lid is closed (sensor inaccessible).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.fprintd.enable = true;
    environment.systemPackages = [pkgs.fprintd];

    services.acpid = lib.mkIf cfg.disableOnLidClose {
      enable = true;
      lidEventCommands = ''
        lid_state=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null | awk '{print $2}')
        if [ "$lid_state" = "closed" ]; then
          systemctl mask --runtime fprintd.service
          systemctl stop fprintd.service
        else
          systemctl unmask fprintd.service
        fi
      '';
    };
  };
}
