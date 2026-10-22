{
  modulesPath,
  config,
  lib,
  ...
}: {
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot.loader.grub.device = "/dev/sda";
  # /boot is 105 MB and a kernel + initrd is ~44 MB: two generations with
  # different kernels fit, three do not (a kernel bump then fails mid-switch).
  boot.loader.grub.configurationLimit = 2;

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
    "virtio_pci"
    "virtio_scsi"
  ];
  boot.initrd.kernelModules = [
    "nvme"
    "dm-snapshot"
  ];

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0683-2D32";
    fsType = "vfat";
  };
  fileSystems."/srv/docker" = {
    device = "localhost:/gv0";
    fsType = "glusterfs";
    options = ["nofail"];
  };
}
