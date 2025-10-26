{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.modules.system.gpu.nvidia;
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.system.gpu.nvidia.enable =
    mkEnableOption "gpu";
  config = mkIf cfg.enable {
    hardware = {
      graphics.extraPackages = [
        pkgs.nvidia-vaapi-driver
      ];

      nvidia = {
        open = lib.mkDefault true;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        modesetting.enable = true;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
      };
    };
    services.xserver.videoDrivers = [
      "nvidia"
    ];
    environment.systemPackages = builtins.attrValues {
      inherit
        (pkgs)
        mesa
        vulkan-tools
        vulkan-loader
        libva
        libva-utils
        ;
      inherit (pkgs.nvtopPackages) nvidia;
    };
    # Nouveau is a set of free and open-source drivers for NVIDIA GPUs
    # that provide 2D/3D acceleration for all NVIDIA GPUs.
    # Its use is in general not recommended due to its considerably worse
    # performance compared to NVIDIA's kernel modules, as it does not
    # support reclocking (changing the GPU clock frequency on-demand)
    # for many NVIDIA GPUs.
    # I therefore disable it to save myself from headaches.
    boot.blacklistedKernelModules = mkIf cfg.enable ["nouveau"];
  };
}
