{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.service.ssh-notify;
  username = config.modules.system.username;
  loginscript = pkgs.writeShellApplication {
    name = "ssh-login-notify";
    bashOptions = [];
    runtimeInputs = [ pkgs.curl pkgs.gawk pkgs.jq ];
    runtimeEnv = {
      TELEGRAM_CHAT_ID = cfg.telegramChatId;
      TELEGRAM_BOT_TOKEN = cfg.telegramBotToken;
    };
    text = ''
#!/bin/bash

LOGGED_USER=$PAM_USER
LOGGED_HOST="$(hostname -f)"
HOST_IP=$(hostname -I | awk '{print $1}')

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

  options.modules.service.ssh-notify = {
    enable = mkEnableOption "Notify on SSH login";
    telegramChatId = mkOption {
      type = types.str;
      description = "Telegram chat ID to send notifications to.";
    };

    telegramBotToken = mkOption {
      type = types.str;
      description = "Telegram bot token to use for sending notifications.";
    };
  };


 config = mkIf cfg.enable {
  security.pam.services.sshd.rules.session.login_msg = {
          enable = true;
          control = "optional";
          order = config.security.pam.services.sshd.rules.session.systemd.order + 1;
          modulePath = "${pkgs.pam.outPath}/lib/security/pam_exec.so";
          args = [ "${loginscript.outPath}/bin/ssh-login-notify" ];
    };
  };

}
