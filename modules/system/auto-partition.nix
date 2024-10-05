{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.disks;
  inherit (config.modules.system) username;
  inherit (config.users.users.${username}) uid;
  inherit (lib) mkIf types mapAttrs mkOption mkEnableOption;
in {
  options.modules.system.disks = {
    auto-partition.enable = mkEnableOption "disko";
    main-disk = mkOption {
      type = types.nullOr types.str;
      description = "The disk the system should be installed on";
      example = "/dev/nvme0n1";
      default = null;
    };
    esp-size = mkOption {
      type = types.strMatching "^[0-9]+[KMGTP]$";
      description = "Size the ESP (efi system partition should have)";
      default = "1G"; # I prefer 1GB since I have run out of space with NixOS before
      example = "512M";
    };
    swap-size = mkOption {
      # taken from https://github.com/nix-community/disko/blob/master/lib/types/btrfs.nix
      # but without the '?' after the expression since I require a nonempty string
      type = types.nullOr (types.strMatching "^[0-9]+[KMGTP]$");
      description = "Size the swapfile should have (possible units: K, M, G, T, P or none)";
      default = "32G";
      example = "1024M";
    };
    storage-disks = mkOption {
      type = types.attrsOf types.str;
      description = "Declare additional storage disks (The whole disk will be a btrfs volume)";
      default = {};
      example = {"extra" = "/dev/sda";};
    };
    name-suffix = mkOption {
      type = types.str;
      description = ''        Will rename partitions and cryptvolumes.
                MUST BE USED WHEN USING THIS CONFIGURATION AS INSTALLER FOR OTHER DEVICES.
                Otherwise disko can mess up existing partitions since they are called the same
      '';
      default = "";
      example = "INST";
    };
  };

  config = mkIf cfg.auto-partition.enable {
    assertions = [
      {
        assertion = !((uid == null) && (cfg.storage-disks == {}));
        message = "To mount storage disks, the uid (users.users.<name>.uid) must be set!";
      }
    ];

    services.btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = ["/"];
    };
    boot = {
      initrd.supportedFilesystems = ["btrfs"];
      supportedFilesystems = ["btrfs"];
      loader = {
        efi.efiSysMountPoint = "/boot";
        efi.canTouchEfiVariables = true;
        grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = true;
          extraEntries = ''
            menuentry "Reboot" {
              reboot
            }
            menuentry "Poweroff" {
              halt
            }
          '';
        };
      };
      # initrd.luks.devices = {
      #   cryptroot = {
      #     preLVM = true;
      #   };
      # };
    };

    # reference: https://haseebmajid.dev/posts/2024-07-30-how-i-setup-btrfs-and-luks-on-nixos-using-disko/
    disko.devices = {
      disk =
        {
          main = {
            type = "disk";
            device = cfg.main-disk;
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  label = "boot" + cfg.name-suffix;
                  size = cfg.esp-size;
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = ["defaults"];
                  };
                };
                root = {
                  size = "100%";
                  label = "luks" + cfg.name-suffix;
                  content = {
                    type = "luks";
                    name = "cryptroot" + cfg.name-suffix;
                    content = {
                      type = "btrfs";
                      extraArgs = ["-L" "nixos${cfg.name-suffix}" "-f"];
                      subvolumes = {
                        "/root" = {
                          mountpoint = "/";
                          mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                        };
                        "/home" = {
                          mountpoint = "/home";
                          mountOptions = ["subvol=home" "compress=zstd" "noatime"];
                        };
                        "/nix" = {
                          mountpoint = "/nix";
                          mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                        };
                        "/log" = {
                          mountpoint = "/var/log";
                          mountOptions = ["subvol=log" "compress=zstd" "noatime"];
                        };
                        "/swap" = mkIf (cfg.swap-size != null) {
                          mountpoint = "/swap";
                          swap.swapfile.size = cfg.swap-size;
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        }
        // lib.mapAttrs (
          name: device: {
            type = "disk";
            device = device;
            content = {
              type = "gpt";
              partitions = {
                "${name}${cfg.name-suffix}" = {
                  size = "100%";
                  label = "luks-${name}${cfg.name-suffix}";
                  content = {
                    type = "luks";
                    name = "crypt-${name}${cfg.name-suffix}";
                    content = {
                      type = "btrfs";
                      extraArgs = ["-L" "${name}${cfg.name-suffix}" "-f"];
                      subvolumes = {
                        "/${name}" = {
                          mountpoint = "/disk-${name}";
                          # make accessible for user
                          mountOptions = ["subvol=${name}" "compress=zstd" "noatime"];
                        };
                      };
                    };
                  };
                };
              };
            };
          }
        )
        cfg.storage-disks;
    };
    fileSystems."/var/log".neededForBoot = true;
    # needed so that the non-boot disks are also decrypted
    boot.initrd.luks.reusePassphrases = true;
  };
}
