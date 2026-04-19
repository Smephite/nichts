{
  options,
  config,
  lib,
  self,
  ...
}: let
  keys = import (self + "/secrets/ssh/public_keys.nix");
  masterKeys = import (self + "/secrets/ssh/master_keys.nix");
  cfg = config.modules.system.authorizedKeys;
  username = config.modules.system.username;
  inherit (lib) types mkIf mkOption;
in {
  options.modules.system.authorizedKeys = {
    defaultKeys = mkOption {
      type = types.listOf types.str;
      default = masterKeys;
    };

    enable = lib.mkEnableOption "Automatically populate the authorized keys for root and admin user with the default ones";
  };

  config.users.users.${username}.openssh.authorizedKeys.keys = mkIf cfg.enable cfg.defaultKeys;
  config.users.users.root.openssh.authorizedKeys.keys = mkIf cfg.enable cfg.defaultKeys;
}
