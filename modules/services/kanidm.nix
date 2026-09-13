{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib; let
  cfg = config.modules.services.kanidm;

  # A secret that has not been created yet must not make the whole config
  # unbuildable. hashFile throws on a missing file.
  hashIfExists = f:
    if builtins.pathExists f
    then builtins.hashFile "sha256" f
    else "absent";
in {
  # kanidm as a native service.
  #
  # TLS is only the loopback hop from Caddy. kanidm will not start without a
  # certificate, so it gets a long-lived self-signed pair from agenix - the
  # certificate users see is Caddy's wildcard, and Caddy skips verification on
  # this hop.
  options.modules.services.kanidm = {
    enable = mkEnableOption "kanidm identity provider";

    domain = mkOption {
      type = types.str;
      example = "idm.kai.run";
      description = ''
        Changing this invalidates registered credentials (webauthn is bound to
        it) and requires `kanidmd domain rename`.
      '';
    };

    origin = mkOption {
      type = types.str;
      example = "https://idm.kai.run";
      description = "Public URL. Must match or be a descendant of domain.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8443";
      description = "Loopback only; Caddy is the sole client.";
    };

    trustedProxies = mkOption {
      type = types.listOf types.str;
      default = ["127.0.0.1"];
      description = ''
        Sources permitted to set X-Forwarded-For. Without this kanidm records
        the proxy as the client for every request in its audit log.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.kanidmWithSecretProvisioning_1_11;
      description = ''
        The secret-provisioning variant is required for provision.enable with
        an admin password or oauth2 basicSecretFile.
      '';
    };
  };

  config = mkIf cfg.enable {
    age.secrets.kanidm-tls-chain = {
      file = self + "/secrets/kanidm/${config.networking.hostName}-tls-chain.age";
      owner = "kanidm";
    };

    age.secrets.kanidm-tls-key = {
      file = self + "/secrets/kanidm/${config.networking.hostName}-tls-key.age";
      owner = "kanidm";
      mode = "0400";
    };

    services.kanidm = {
      package = cfg.package;
      server.enable = true;
      # db_path is read-only - the module fixes it at /var/lib/kanidm/kanidm.db
      # via StateDirectory, which is where we want it anyway.
      server.settings = {
        inherit (cfg) domain origin;
        bindaddress = cfg.bindAddress;
        # Must be real paths, not nix store paths - the upstream module asserts
        # against the store so the key is never world-readable.
        tls_chain = config.age.secrets.kanidm-tls-chain.path;
        tls_key = config.age.secrets.kanidm-tls-key.path;
        http_client_address_info.x-forward-for = cfg.trustedProxies;
      };
    };

    systemd.services.kanidm = {
      after = ["agenix.service"];
      wants = ["agenix.service"];
      restartTriggers = [
        (hashIfExists config.age.secrets.kanidm-tls-chain.file)
        (hashIfExists config.age.secrets.kanidm-tls-key.file)
      ];
    };
  };
}
