{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib; let
  cfg = config.modules.services.kanidmMailSender;
  clientConfig = pkgs.writeText "kanidm-mail-sender-client.toml" ''
    uri = "${cfg.clientUri}"
  '';
in {
  # Drains kanidm's outbound message queue and sends the mail.
  #
  # kanidmd never sends anything itself - it queues messages in its database.
  # This is what makes credential-reset links arrive by email instead of being
  # copied out of a terminal.
  #
  # Run ONE instance only. Each queued message is delivered at least once, so a
  # second instance means duplicate mail.
  options.modules.services.kanidmMailSender = {
    enable = mkEnableOption "kanidm outbound mail sender";

    clientUri = mkOption {
      type = types.str;
      example = "https://idm.kai.run";
      description = "Kanidm instance this sender connects to.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.kanidm_1_11;
      description = "Must match the kanidm server version.";
    };
  };

  config = mkIf cfg.enable {
    # Holds both the API token and the SMTP password, so the whole file is a
    # secret. Non-secret settings (relay, addresses) live in it too - same
    # approach as the caddy config.
    age.secrets.kanidm-mail-sender = {
      file = self + "/secrets/kanidm/${config.networking.hostName}-mail-sender.age";
      owner = "kanidm-mail-sender";
    };

    users.users.kanidm-mail-sender = {
      isSystemUser = true;
      group = "kanidm-mail-sender";
    };
    users.groups.kanidm-mail-sender = {};

    systemd.services.kanidm-mail-sender = {
      description = "Kanidm outbound mail sender";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "agenix.service"];
      wants = ["network-online.target" "agenix.service"];

      # The config is a runtime secret, so its content changing alters no store
      # path. Without this, a rebuild would leave the old config running.
      restartTriggers = [
        (builtins.hashFile "sha256" config.age.secrets.kanidm-mail-sender.file)
      ];

      serviceConfig = {
        User = "kanidm-mail-sender";
        Group = "kanidm-mail-sender";
        ExecStart = "${cfg.package}/bin/kanidm-mail-sender -c ${clientConfig} -m ${config.age.secrets.kanidm-mail-sender.path}";
        Restart = "on-failure";
        RestartSec = "30s";

        # It needs only outbound network and one secret.
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      };
    };
  };
}
