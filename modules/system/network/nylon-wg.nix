{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.modules.system.network.nylon-wg;
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.system.network.nylon-wg = {
    enable = mkEnableOption "nylon";
    
    centralConfig = lib.mkOption {
        type = with lib.types; path;
        description = "Path to nylon central config.";
      };

      node = {
        key = lib.mkOption {
          type = with lib.types; either path str;
          description = ''
            Node key as string or path to node key
            A path is preferred as else the key will be commited to the nix-store.
          '';
        };
        port = lib.mkOption {
          type = with lib.types; int;
          default = 57175;
          description = "Port for nylon to listen on.";
        };
        interface = lib.mkOption {
          type = with lib.types; str;
          default = "nylon";
          description = "Interface for nylon to listen on.";
        };
        id = lib.mkOption {
          type = with lib.types; str;
          description = "Nylon node id";
        };
        logPath = lib.mkOption {
          type = with lib.types; nullOr path;
          default = null;
          description = "Log to this file";
        };
        noNetConfigure = lib.mkOption {
          type = with lib.types; bool;
          default = false;
          description = "Do not configure the system network settings.";
        };
        useSystemRouting = lib.mkOption {
          type = with lib.types; bool;
          default = false;
          description = "Use the system route table to forward packets";
        };
        disableRouting = lib.mkOption {
          type = with lib.types; bool;
          default = false;
          description = "Do not route traffic through this node";
        };
      };

      openFirewall = lib.mkOption {
        type = with lib.types; bool;
        default = true;
        description = "Configure firewall to trust nylon port and interface";
      };
    };

  config = mkIf cfg.enable {

    age.secrets.nylon_central.file = self + "/secrets/nylon.central.age";
    
    services.nylon-wg = {
      enable = true;
      centralConfig = cfg.centralConfig or config.age.secrets.nylon_central.path;
      node = {
        inherit (cfg.node) port interface disableRouting useSystemRouting noNetConfigure logPath;
        id = cfg.node.id or (config.networking.hostName + "." + config.networking.domain);
        key = cfg.node.key;
      };
      openFirewall = true;
    };

  };
}
