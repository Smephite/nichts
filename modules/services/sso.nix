{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.modules.services.sso;
in {
  # oauth2-proxy + redis, the forward-auth layer Caddy calls.
  #
  # Native rather than containerised so it sits alongside the Caddy module and
  # takes its secrets from agenix. Neither service is exposed: oauth2-proxy
  # binds loopback and is reached only by Caddy on the same host, and redis
  # binds loopback too.
  #
  # redis is NOT optional. kanidm issues single-use refresh tokens with replay
  # detection, and oauth2-proxy's default cookie store cannot lock across
  # concurrent requests - parallel refreshes then look like a replay, kanidm
  # destroys the session, and the user is stuck in a login loop. The redis
  # store serialises refresh. It also keeps the session out of the cookie,
  # which otherwise approaches the 4096-byte limit once a user is in many
  # groups.
  options.modules.services.sso = {
    enable = mkEnableOption "kanidm-backed forward auth (oauth2-proxy + redis)";

    clientID = mkOption {
      type = types.str;
      default = "proxy";
      description = "OAuth2 client name registered in kanidm.";
    };

    issuerUrl = mkOption {
      type = types.str;
      example = "https://idm.kai.run/oauth2/openid/proxy";
      description = "kanidm OIDC issuer for this client.";
    };

    redirectURL = mkOption {
      type = types.str;
      example = "https://sso.kai.run:9443/oauth2/callback";
      description = ''
        Must match a redirect URL registered on the kanidm client exactly -
        kanidm enforces strict redirect URIs.
      '';
    };

    cookieDomain = mkOption {
      type = types.str;
      example = ".kai.run";
      description = "Cookie domain; a leading dot covers every subdomain.";
    };

    whitelistDomains = mkOption {
      type = types.listOf types.str;
      example = [".kai.run:9443"];
      description = ''
        Domains oauth2-proxy may redirect back to after login. Include the
        port while Caddy is not on 443, or post-login redirects are refused.
      '';
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:4180";
      description = "Loopback only; Caddy is the sole client.";
    };

    trustedProxyIPs = mkOption {
      type = types.listOf types.str;
      default = ["127.0.0.1/32" "::1/128"];
      description = ''
        Who may set X-Forwarded-* headers. Without this oauth2-proxy trusts
        every source, so any client could spoof its apparent address.
      '';
    };

    cookieRefresh = mkOption {
      type = types.str;
      default = "5m";
      description = ''
        How often the session is re-validated against kanidm by exchanging the
        refresh token. This is what makes revoking a group take effect; without
        it the groups baked in at login stand for the full cookie lifetime.
      '';
    };

    redisPort = mkOption {
      type = types.port;
      default = 6379;
    };
  };

  config = mkIf cfg.enable {
    age.secrets.oauth2-proxy-client-secret = {
      file = self + "/secrets/sso/${config.networking.hostName}-client-secret.age";
      owner = "oauth2-proxy";
    };

    age.secrets.oauth2-proxy-cookie-secret = {
      file = self + "/secrets/sso/${config.networking.hostName}-cookie-secret.age";
      owner = "oauth2-proxy";
    };

    services.redis.servers.oauth2-proxy = {
      enable = true;
      bind = "127.0.0.1";
      port = cfg.redisPort;
      # Sessions only. Losing them on restart is preferable to stale ones
      # surviving, and it avoids writing session material to disk.
      save = [];
      appendOnly = false;
    };

    services.oauth2-proxy = {
      enable = true;
      provider = "oidc";
      clientID = cfg.clientID;
      clientSecretFile = config.age.secrets.oauth2-proxy-client-secret.path;
      oidcIssuerUrl = cfg.issuerUrl;
      redirectURL = cfg.redirectURL;
      httpAddress = "http://${cfg.listenAddress}";
      reverseProxy = true;
      email.domains = ["*"];

      cookie = {
        secretFile = config.age.secrets.oauth2-proxy-cookie-secret.path;
        domain = cfg.cookieDomain;
        secure = true;
        refresh = cfg.cookieRefresh;
      };

      extraConfig = {
        # kanidm's groups_spn scope emits SPNs only; the plain groups scope
        # also emits a UUID per group, roughly doubling the claim for nothing.
        # The requested scope must match the kanidm scope map exactly, or
        # authorisation fails as an opaque "Access Denied" with only an
        # Operation ID.
        scope = "openid profile email groups_spn";
        oidc-groups-claim = "groups";

        # kanidm enforces PKCE on confidential clients.
        code-challenge-method = "S256";

        # X-Auth-Request-User is the OIDC sub, which kanidm sets to the account
        # UUID. Caddy copies Preferred-Username instead; this just enables the
        # header family.
        set-xauthrequest = true;

        # Accounts without a mail attribute emit no email claim, and
        # oauth2-proxy refuses to build a session without one.
        oidc-email-claim = "preferred_username";

        session-store-type = "redis";
        redis-connection-url = "redis://127.0.0.1:${toString cfg.redisPort}";

        skip-provider-button = true;
        upstream = "static://202";
        whitelist-domain = cfg.whitelistDomains;
        trusted-proxy-ip = cfg.trustedProxyIPs;
      };
    };
  };
}
