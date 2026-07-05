{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.sshfs-mounts;
  mUser = config.modules.system.username;
in {
  options.modules.sshfs-mounts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
      options = {
        enable = lib.mkEnableOption "this SSHFS mount";
        uri = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "SSH target passed to sshfs. Defaults to the attr name.";
        };
        remotePath = lib.mkOption {
          type = lib.types.str;
          default = "/";
          description = "Remote path to mount.";
        };
        localPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Local mount point. Defaults to ~/mnt/<name> when null.";
        };
        jumpHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "SSH jump host, e.g. `bastion` or `user@gateway`.";
        };
      };
    }));
    default = {};
    description = "SSHFS mounts managed as user services.";
  };

  config = let
    enabledMounts = lib.filterAttrs (_: mount: mount.enable) cfg;
  in
    lib.mkIf (enabledMounts != {}) {
      environment.systemPackages = [pkgs.sshfs];

      systemd.user.services = lib.mapAttrs' (mName: mount: let
        mPath =
          if mount.localPath != null
          then mount.localPath
          else "/home/${mUser}/mnt/${mName}";
      in
        lib.nameValuePair "sshfs-${mName}" {
          description = "SSHFS mount of ${mount.uri}:${mount.remotePath} at ${mPath}";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          wantedBy = ["default.target"];
          startLimitIntervalSec = 0;
          serviceConfig = {
            Type = "simple";
            ExecStartPre = [
              "${pkgs.coreutils}/bin/mkdir -p ${mPath}"
              "-${pkgs.writeShellScript "sshfs-cleanup-${mName}" ''
                ${pkgs.util-linux}/bin/mountpoint -q ${mPath} && ${pkgs.fuse3}/bin/fusermount3 -u ${mPath}
              ''}"
            ];
            ExecStart = let
              jumpFlag = lib.optionalString (mount.jumpHost != null) "-o ProxyJump=${mount.jumpHost} ";
            in "${pkgs.sshfs}/bin/sshfs -f -o reconnect,delay_connect=10,ServerAliveInterval=15,ServerAliveCountMax=3 ${jumpFlag}${mount.uri}:${mount.remotePath} ${mPath}";
            ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u ${mPath}";
            Restart = "on-failure";
            RestartSec = "60";
          };
        })
      enabledMounts;
    };
}
