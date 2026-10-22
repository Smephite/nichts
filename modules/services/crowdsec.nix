{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.services.crowdsec;
  caddy = config.modules.services.caddy;
  stateDir = "/var/lib/crowdsec/state";
in {
  # CrowdSec reads the sshd journal and Caddy's access log, and the firewall
  # bouncer drops banned addresses in INPUT - before they reach sshd or Caddy.
  #
  # INPUT only: Docker-published ports (mailcow's SMTP/IMAP) are forwarded and
  # never traverse INPUT. mailcow's own netfilter container covers those.
  #
  # The community blocklist (CAPI) is pulled too, so known scanners are dropped
  # before they try anything here. Private ranges (LAN, WireGuard) are never
  # banned: crowdsecurity/whitelists, part of the linux collection.
  options.modules.services.crowdsec = {
    enable = mkEnableOption "CrowdSec with the iptables firewall bouncer";

    whitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["2001:db8::/48"];
      description = "Public CIDRs that are never banned (own networks).";
    };
  };

  config = mkIf cfg.enable {
    services.crowdsec = {
      enable = true;
      autoUpdateService = true;

      hub.collections =
        ["crowdsecurity/linux"] # sshd parsers/scenarios + private-range whitelist
        ++ optionals caddy.enable ["crowdsecurity/caddy" "crowdsecurity/http-cve"];

      localConfig = {
        acquisitions =
          [
            {
              source = "journalctl";
              journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
              labels.type = "syslog";
            }
          ]
          ++ optional caddy.enable {
            filenames = ["/var/log/caddy/access.log"];
            labels.type = "caddy";
          };

        parsers.s02Enrich = optional (cfg.whitelist != []) {
          name = "nichts/own-networks";
          description = "Never ban our own public networks";
          whitelist = {
            reason = "own network";
            cidr = cfg.whitelist;
          };
        };

        # Without profiles CrowdSec detects but never decides anything.
        # These are upstream's defaults.
        profiles = [
          {
            name = "default_ip_remediation";
            filters = ["Alert.Remediation == true && Alert.GetScope() == 'Ip'"];
            decisions = [
              {
                type = "ban";
                duration = "4h";
              }
            ];
            on_success = "break";
          }
          {
            name = "default_range_remediation";
            filters = ["Alert.Remediation == true && Alert.GetScope() == 'Range'"];
            decisions = [
              {
                type = "ban";
                duration = "4h";
              }
            ];
            on_success = "break";
          }
        ];
      };

      settings = {
        # The local API is what the bouncer polls; off by default in the module.
        general.api.server.enable = true;
        lapi.credentialsFile = "${stateDir}/local_api_credentials.yaml";
        # Registered on first start; enables the community blocklist.
        capi.credentialsFile = "${stateDir}/online_api_credentials.yaml";

        # app.crowdsec.net. Enrol once by hand: `sudo cscli console enroll <key>`.
        # Not via console.tokenFile: the module only enrols when that file is
        # MISSING (and then cats it), so it never works.
        console.configuration = {
          console_management = true; # add/remove bans from the web UI
          share_manual_decisions = true;
          share_custom = false;
          share_tainted = false;
          share_context = false; # keep log lines on the box
        };
      };
    };

    # Caddy writes its access log 0640 caddy:caddy (see the log block in the
    # Caddy services secret).
    users.users.crowdsec.extraGroups = optional caddy.enable "caddy";

    services.crowdsec-firewall-bouncer.enable = true;
  };
}
