{ modulesPath, config, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  
  boot.loader.grub.device = "/dev/sda";
  # Not much space on /boot
  boot.loader.grub.configurationLimit = 3;
  
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" "virtio_pci" "virtio_scsi"];
  boot.initrd.kernelModules = [ "nvme" "dm-snapshot" ];

  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-uuid/0683-2D32"; fsType = "vfat"; };
  fileSystems."/srv/docker" = { device = "localhost:/gv0"; fsType = "glusterfs"; options = [ "nofail" ]; };
}
