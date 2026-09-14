{pkgs, ...}: let
  site = pkgs.dsa-lexicon-site;

  dataDir = "/var/lib/dsa-lexicon/pdfs";

  caddyfile = pkgs.writeText "dsa-lexicon.Caddyfile" ''
    {
    	admin off
    	auto_https off
    }

    :4173 {
    	handle_path /pdfs/* {
    		root * "${dataDir}"
    		file_server
    	}

    	handle {
    		encode zstd gzip
    		root * ${site}/share/dsa-lexicon
    		file_server
    	}
    }
  '';
in {
  systemd.services.dsa-lexicon = {
    description = "Static file server";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    environment = {
      HOME = "/run/dsa-lexicon";
      XDG_DATA_HOME = "/run/dsa-lexicon/data";
      XDG_CONFIG_HOME = "/run/dsa-lexicon/config";
    };

    serviceConfig = {
      DynamicUser = true;

      RuntimeDirectory = "dsa-lexicon";
      RuntimeDirectoryMode = "0750";

      ExecStart = "${pkgs.caddy}/bin/caddy run --config ${caddyfile} --adapter caddyfile";
      ExecReload = "${pkgs.caddy}/bin/caddy reload --config ${caddyfile} --adapter caddyfile --force";

      Restart = "on-failure";
      RestartSec = 5;

      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      LockPersonality = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dsa-lexicon 0755 root root -"
  ];

  networking.firewall.interfaces.nylon.allowedTCPPorts = [4173];
}
