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
  openconnect = "/run/wrappers/bin/openconnect";
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
          ${lib.optionalString (profile.oath.yubikey.passwordFile != null) ''
          OATH_PASSWORD=$(cat ${lib.escapeShellArg profile.oath.yubikey.passwordFile})
        ''}
          OTP=$(${ykman} oath accounts code \
            ${
          lib.optionalString (profile.oath.yubikey.passwordFile != null) ''--password "$OATH_PASSWORD"''
        } \
            "$YUBIKEY_ACCOUNT" | awk '{print $NF}')
        elif [[ -n "$TOTP" ]]; then
          OTP=$(${oathtool} --totp --base32 "$TOTP")
        fi

        {
          echo "$PASSWORD"
          [[ -n "$OTP" ]] && echo "$OTP" || true
        } | ${openconnect} \
          -u "$USERNAME" \
          --server "$URL" \
          ''${GROUP:+-g "$GROUP"} \
          --useragent=AnyConnect \
          --passwd-on-stdin
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
            OTP=$(${ykman} oath accounts code \
              ${lib.optionalString (oath.yubikey.passwordFile != null) ''--password "$OATH_PASSWORD"''} \
              ${lib.escapeShellArg oath.yubikey.account} | awk '{print $NF}')
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

    environment.systemPackages = lib.mapAttrsToList makeScript cfg.scripts.profiles;
  };
}
