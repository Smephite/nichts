{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "rpool/ROOT/default";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  # fileSystems."/home" =
  #   { device = "rpool/data/home";
  #     fsType = "zfs";
  #   };

  fileSystems."/nix" = {
    device = "rpool/data/nix";
    fsType = "zfs";
    options = ["zfsutil"];
  };

  # fileSystems."/var/log" =
  #   { device = "rpool/data/var/log";
  #     fsType = "zfs";
  #   };
  #

  boot.loader.grub.device = "/dev/disk/by-id/nvme-Samsung_SSD_960_PRO_512GB_S3EWNX0K401532W-part2";

  fileSystems."/boot" = {
    device = "bpool/boot";
    fsType = "zfs";
    # options = [ "zfsutil" ];
  };

  /*
  fileSystems."/boot/efis" =
    { device = "bpool/boot/efis";
      fsType = "zfs";
      # options = [ "zfsutil" ];
    };
  */

  # fileSystems."/boot/nixos/root" =
  #   { device = "bpool/nixos/root";
  #     fsType = "zfs";
  #   };

  /*
  fileSystems."/boot/efis/ata-KINGSTON_SA400S37960G_50026B7783226E2F-part1" =
    { device = "/dev/disk/by-uuid/2557-B645";
      fsType = "vfat";
      depends = [ "/boot/efis" ];
      mountPoint = "/boot/efis/ata-KINGSTON_SA400S37960G_50026B7783226E2F-part1";
    };
  */

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-id/nvme-Samsung_SSD_960_PRO_512GB_S3EWNX0K401532W-part1"; #"/dev/disk/by-uuid/2558-3353";
    fsType = "vfat";
    depends = ["/boot"];
    mountPoint = "/boot/efi";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/33c703bc-0ca0-41cb-8e75-a6f5a0405a04";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
