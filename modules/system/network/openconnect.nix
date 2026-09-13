{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.network.openconnect;
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  ykman = "${pkgs.yubikey-manager}/bin/ykman";
  oathtool = "${pkgs.oath-toolkit}/bin/oathtool";
  rbw = "${pkgs.rbw}/bin/rbw";
  openconnect = "${pkgs.openconnect}/bin/openconnect";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  yq = "${pkgs.yq-go}/bin/yq";

  # ---------------------------------------------------------------------------
  # Profile — set file to load connection details from a structured file at
  # runtime, or leave it null and declare all values explicitly in Nix.
  #
  # File format (when file is set):
  #   vpn:
  #     username:        <user>
  #     password:        <pass>
  #     url:             <server url>
  #     group:           <tunnel group>   (optional)
  #     totp:            yubikey          (or a base32 TOTP secret, or omitted)
  #     yubikey_account: <account>        (required when totp: yubikey)
  #     rbw_entry:       <name>           (optional — Bitwarden fallback for TOTP)
  # ---------------------------------------------------------------------------

  profileModule = types.submodule {
    options = {
      file = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to a structured profile file (e.g. config.age.secrets.\"uni.vpn\".path). When set, the explicit options below are ignored.";
      };

      # Explicit connection details — used when file is null
      server = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "VPN server hostname. Required when file is null.";
      };
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "VPN username. Required when file is null.";
      };
      group = mkOption {
        type = types.str;
        default = "";
        description = "VPN tunnel group. Omitted if empty.";
      };
      userAgent = mkOption {
        type = types.str;
        default = "AnyConnect";
        description = "User-Agent header sent to the VPN server";
      };
      passwordFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to a file containing the VPN password. Required when file is null.";
      };

      # OTP — when file is set only yubikey.passwordFile is used (method and
      # account are read from the file); all options apply when file is null.
      oath = {
        enable = mkEnableOption "OTP as second factor";
        method = mkOption {
          type = types.enum [
            "yubikey"
            "totp"
          ];
          default = "yubikey";
          description = "OTP method: yubikey uses ykman OATH; totp uses oathtool with a stored secret. Used when file is null.";
        };
        yubikey = {
          account = mkOption {
            type = types.str;
            default = "";
            description = "OATH account name as shown by ykman (e.g. ETHZ:kberszin). Used when file is null and method = yubikey.";
          };
          passwordFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Path to a file containing the YubiKey OATH unlock password. Null if the YubiKey has no password.";
          };
        };
        totp = {
          secretFile = mkOption {
            type = types.str;
            default = "";
            description = "Path to a file containing the base32 TOTP secret. Used when file is null and method = totp.";
          };
        };
        rbw = {
          entry = mkOption {
            type = types.str;
            default = "";
            description = "Bitwarden entry name for rbw TOTP fallback when YubiKey is unavailable.";
          };
        };
      };
    };
  };

  makeScript = name: profile:
    if profile.file != null
    then
      # Runtime-parsed script: reads connection details from the structured file
      pkgs.writeShellScriptBin "vpn-${name}" ''
        set -euo pipefail

        vpn() { ${yq} ".vpn.$1" ${lib.escapeShellArg profile.file}; }

        USERNAME=$(vpn username)
        PASSWORD=$(vpn password)
        URL=$(vpn url)
        GROUP=$(vpn group | grep -v '^null$' || true)
        TOTP=$(vpn totp | grep -v '^null$' || true)
        OTP=""

        if [[ "$TOTP" == "yubikey" ]]; then
          YUBIKEY_ACCOUNT=$(vpn yubikey_account)
          RBW_ENTRY=$(vpn rbw_entry | grep -v '^null$' || true)
          ${lib.optionalString (profile.oath.yubikey.passwordFile != null) ''
          OATH_PASSWORD=$(cat ${lib.escapeShellArg profile.oath.yubikey.passwordFile})
        ''}
          if OTP=$(${ykman} oath accounts code \
            ${
          lib.optionalString (profile.oath.yubikey.passwordFile != null) ''--password "$OATH_PASSWORD"''
        } \
            "$YUBIKEY_ACCOUNT" 2>/dev/null | awk '{print $NF}'); then
            :
          elif [[ -n "$RBW_ENTRY" ]]; then
            echo "YubiKey not available, falling back to Bitwarden" >&2
            OTP=$(${rbw} code "$RBW_ENTRY")
          else
            echo "YubiKey not available and no rbw_entry configured" >&2
            exit 1
          fi
        elif [[ -n "$TOTP" ]]; then
          OTP=$(${oathtool} --totp --base32 "$TOTP")
        fi

        # Authenticate and get session cookie
        AUTH_OUTPUT=$({
          echo "$PASSWORD"
          [[ -n "$OTP" ]] && echo "$OTP" || true
        } | ${openconnect} --authenticate \
          -u "$USERNAME" \
          --server "$URL" \
          ''${GROUP:+-g "$GROUP"} \
          --useragent=AnyConnect \
          --passwd-on-stdin 2>&1)

        eval "$(echo "$AUTH_OUTPUT" | grep -E '^(COOKIE|HOST|FINGERPRINT)=')"

        if [[ -z "''${COOKIE:-}" ]]; then
          echo "Authentication failed:" >&2
          echo "$AUTH_OUTPUT" >&2
          exit 1
        fi

        # Ensure NM connection profile exists
        CON_NAME="vpn-${name}"
        ${nmcli} connection show "$CON_NAME" &>/dev/null || \
          ${nmcli} connection add type vpn con-name "$CON_NAME" \
            vpn-type openconnect \
            vpn.data "gateway = $URL, protocol = anyconnect, useragent = AnyConnect"

        # Inject secrets in-memory and activate
        ${nmcli} connection modify --temporary "$CON_NAME" \
          vpn.secrets "cookie = $COOKIE, gateway = $HOST, gwcert = $FINGERPRINT"
        ${nmcli} connection up "$CON_NAME"
        echo "VPN connected via NetworkManager. Disconnect from network panel or: nmcli connection down $CON_NAME" >&2
      ''
    else
      # Static script: all values baked in at build time
      let
        oath = profile.oath;
        otpFragment =
          if !oath.enable
          then ""
          else if oath.method == "yubikey"
          then ''
            ${lib.optionalString (oath.yubikey.passwordFile != null) ''
              OATH_PASSWORD=$(cat ${lib.escapeShellArg oath.yubikey.passwordFile})
            ''}
            if OTP=$(${ykman} oath accounts code \
              ${lib.optionalString (oath.yubikey.passwordFile != null) ''--password "$OATH_PASSWORD"''} \
              ${lib.escapeShellArg oath.yubikey.account} 2>/dev/null | awk '{print $NF}'); then
              :
            ${lib.optionalString (oath.rbw.entry != "") ''
              elif true; then
                echo "YubiKey not available, falling back to Bitwarden" >&2
                OTP=$(${rbw} code ${lib.escapeShellArg oath.rbw.entry})
            ''}
            else
              echo "YubiKey not available${lib.optionalString (oath.rbw.entry == "") " and no rbw entry configured"}" >&2
              exit 1
            fi
          ''
          else ''
            TOTP_SECRET=$(cat ${lib.escapeShellArg oath.totp.secretFile})
            OTP=$(${oathtool} --totp --base32 "$TOTP_SECRET")
          '';
      in
        pkgs.writeShellScriptBin "vpn-${name}" ''
          set -euo pipefail

          VPN_PASSWORD=$(cat ${lib.escapeShellArg profile.passwordFile})

          ${otpFragment}

          {
            echo "$VPN_PASSWORD"
            ${lib.optionalString oath.enable ''echo "$OTP"''}
          } | ${openconnect} \
            -u ${lib.escapeShellArg profile.user} \
            --server ${lib.escapeShellArg profile.server} \
            ${lib.optionalString (profile.group != "") "-g ${lib.escapeShellArg profile.group}"} \
            --useragent=${lib.escapeShellArg profile.userAgent} \
            --passwd-on-stdin
        '';
in {
  options.modules.system.network.openconnect = {
    enable = mkEnableOption "openconnect";

    scripts.profiles = mkOption {
      type = types.attrsOf profileModule;
      default = {};
      description = "Named VPN profiles. Set file to load from a structured file at runtime, or declare all values explicitly in Nix.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "modules.system.network.openconnect requires networkmanager to be enabled!";
      }
    ];

    networking.networkmanager.plugins = [pkgs.networkmanager-openconnect];

    security.wrappers.openconnect = {
      source = "${pkgs.openconnect}/bin/openconnect";
      capabilities = "cap_net_admin+ep";
      owner = "root";
      group = "root";
    };

    systemd.tmpfiles.rules = [
      "d /var/run/vpnc 0777 root root -"
    ];

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.resolve1.") === 0 &&
            subject.user === "${config.modules.system.username}") {
          return polkit.Result.YES;
        }
      });
    '';

    environment.systemPackages = lib.mapAttrsToList makeScript cfg.scripts.profiles;
  };
}
