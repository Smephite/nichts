{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib; let
  cfg = config.modules.services.ssh-notify;
  username = config.modules.system.username;
  loginscript = pkgs.writeShellApplication {
    name = "ssh-login-notify";
    bashOptions = [];
    runtimeInputs = [pkgs.curl pkgs.gawk pkgs.jq];
    text = ''
      #!/bin/bash

      LOGGED_USER=$PAM_USER
      LOGGED_HOST="$(hostname -f)"
      HOST_IP=$(hostname -I | awk '{print $1}')
      # shellcheck disable=SC1091
      source ${config.age.secrets.telegram.path}
      LOGGED_IP=$PAM_RHOST
      NOW="$(date)"

      INFO=$(curl "http://ipinfo.io/$LOGGED_IP" -s)
      CITY=$(echo "$INFO" | jq -r .city)
      REGION=$(echo "$INFO" | jq -r .region)
      COUNTRY=$(echo "$INFO" | jq -r .country)

      MESSAGE="<strong>SSH Login Notification</strong>
      Host: $LOGGED_HOST ($HOST_IP)
      User: $LOGGED_USER
      IP: $LOGGED_IP ($CITY, $REGION, $COUNTRY)
      Time: $NOW"

      curl --silent --output /dev/null \
          --data-urlencode "chat_id=${"\${TELEGRAM_CHAT_ID}"}" \
          --data-urlencode "text=${"\${MESSAGE}"}" \
          --data-urlencode "parse_mode=HTML" \
          --data-urlencode "disable_web_page_preview=true" \
          "https://api.telegram.org/bot${"\${TELEGRAM_BOT_TOKEN}"}/sendMessage"

    '';
  };
in {
  options.modules.services.ssh-notify = {
    enable = mkEnableOption "Notify on SSH login";
    telegramSecrets = mkOption {
      type = types.str;
      default = self + "/secrets/telegram.age";
      description = "The secret store to use for telegram bot credentials. Must contain two lines with TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.telegram.file = cfg.telegramSecrets;

    security.pam.services.sshd.rules.session.login_msg = {
      enable = true;
      control = "optional";
      order = config.security.pam.services.sshd.rules.session.systemd.order + 1;
      modulePath = "${pkgs.pam.outPath}/lib/security/pam_exec.so";
      args = ["${loginscript.outPath}/bin/ssh-login-notify"];
    };
  };
}
