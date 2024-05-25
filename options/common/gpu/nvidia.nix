{ config, lib, pkgs, ...}:
{
  # taken from https://github.com/bloxx12/nichts/blob/main/options/common/gpu/nvidia.nix
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    # package = pkgs-unstable.mesa.drivers;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "555.42.02";
      sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
      openSha256 = "sha256-3/eI1VsBzuZ3Y6RZmt3Q5HrzI2saPTqUNs6zPh5zy6w=";
      settingsSha256 = "";
      persistencedSha256 = "";
    };
  };

  
  environment.sessionVariables = lib.mkIf config.modules.WM.hyprland.enable {
    XDG_SESSION_TYPE = "wayland";
    #GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";
    #_JAVA_AWT_WM_NONREPARENTING = "1";
    CLUTTER_BACKEND = "wayland";
    #WLR_RENDERER = "vulkan";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    GTK_USE_PORTAL = "1";
    #NIXOS_XDG_OPEN_USE_PORTAL = "1";
  };
}


