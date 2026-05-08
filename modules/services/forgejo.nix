{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.forgejo;
in {
  options.modules.services.forgejo = {
    enable = mkEnableOption "Forgejo service";
    port = mkOption {
      type = types.port;
      default = 31415;
      description = "Port to listen on";
    };
    rootUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Root URL for Forgejo";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the Forgejo port";
    };
    allowSignups = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to allow user registration";
    };
    requireSignin = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to require users to be signed in to view any pages";
    };
    defaultPrivate = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to make new repositories private by default";
    };
  };

  config = mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      settings = {
        server = {
          HTTP_PORT = cfg.port;
          DOMAIN = config.networking.hostName;
          ROOT_URL =
            if cfg.rootUrl != null
            then cfg.rootUrl
            else "http://${config.networking.hostName}:${toString cfg.port}/";
        };
        service = {
          DISABLE_REGISTRATION = !cfg.allowSignups;
          REQUIRE_SIGNIN_VIEW = cfg.requireSignin;
        };
        repository = {
          DEFAULT_PRIVATE =
            if cfg.defaultPrivate
            then "private"
            else "public";
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];
  };
}
