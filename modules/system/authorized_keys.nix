{
  options,
  config,
  lib,
  self,
  ...
}:
let
  hosts = import (self + "/secrets/public_keys.nix");
  cfg = config.modules.system.authorizedKeys;
  username = config.modules.system.username;
  inherit (lib) types mkIf mkOption;
in {
  options.modules.system.authorizedKeys = {

    defaultKeys = mkOption {
      type = types.listOf types.str;
      default = with hosts; [
        heartofgold
        heartofgold-nix
        silverwind
        silverwind-nix
        yubikey
      ];
    };

    enable = lib.mkEnableOption "Automatically populate the authorized keys for root and admin user with the default ones";
  };
  
    config.users.users.${username}.openssh.authorizedKeys.keys = mkIf cfg.enable cfg.defaultKeys;
    config.users.users.root.openssh.authorizedKeys.keys = mkIf cfg.enable cfg.defaultKeys;
  
}
