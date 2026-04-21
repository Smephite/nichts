{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib; let
  cfg = config.modules.services.caddy;
  hostname = config.networking.hostName;
  caddyPkg = pkgs.caddy.withPlugins {
    plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
    hash = "sha256-Olz4W84Kiyldy+JtbIicVCL7dAYl4zq+2rxEOUTObxA=";
  };
  wrapperConfig = pkgs.writeText "caddy-wrapper.conf" ''
    {
      http_port ${toString cfg.httpPort}
      https_port ${toString cfg.httpsPort}
    }
    import ${config.age.secrets.caddyfile.path}
  '';
in {
  options.modules.services.caddy = {
    enable = mkEnableOption "Caddy reverse proxy with agenix-managed configuration";

    httpPort = mkOption {
      type = types.port;
      default = 80;
      description = "Port for Caddy to listen on for HTTP.";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 443;
      description = "Port for Caddy to listen on for HTTPS.";
    };
  };

  config = mkIf cfg.enable {
    # Declare caddy user/group explicitly so they exist at agenix secret activation time
    users.users.caddy = {
      isSystemUser = true;
      group = "caddy";
      home = "/var/lib/caddy";
      createHome = true;
    };
    users.groups.caddy = {};

    # Agenix secrets
    age.secrets.caddyfile = {
      file = self + "/secrets/caddy/${hostname}-caddyfile.age";
      owner = "caddy";
    };

    age.secrets.caddy-host-services = {
      file = self + "/secrets/caddy/${hostname}-services.age";
      owner = "caddy";
      path = "/run/secrets/caddy-host-services";
    };

    age.secrets.caddy-env = {
      file = self + "/secrets/caddy/env.age";
      owner = "caddy";
    };

    # Caddy service
    services.caddy = {
      enable = true;
      package = caddyPkg;
    };

    # Override systemd service for agenix integration:
    # The NixOS caddy module tries to adapt the Caddyfile at build time,
    # which fails for agenix secrets (only available at runtime).
    # We use a generated wrapper config that sets global port options and
    # imports the agenix-decrypted Caddyfile at runtime.
    systemd.services.caddy = {
      after = ["agenix.service"];
      wants = ["agenix.service"];
      serviceConfig = {
        EnvironmentFile = config.age.secrets.caddy-env.path;
        ExecStart = mkForce ["" "${caddyPkg}/bin/caddy run --config ${wrapperConfig} --adapter caddyfile"];
        ExecReload = mkForce ["" "${caddyPkg}/bin/caddy reload --config ${wrapperConfig} --adapter caddyfile --force"];
      };
    };

    # Open configured HTTP and HTTPS ports
    networking.firewall.allowedTCPPorts = [cfg.httpPort cfg.httpsPort];
  };
}
