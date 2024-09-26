{
  config,
  lib,
  pkgs,
  ...
}: {
  # taken from https://github.com/bloxx12/nichts/blob/main/options/common/gpu/nvidia.nix
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = [
    pkgs.egl-wayland
  ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = false;
  };

  environment.sessionVariables = lib.mkIf config.modules.WM.hyprland.enable {
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    GDK_BACKEND = "wayland";
    # QT_QPA_PLATFORM = "wayland";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "0";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    GTK_USE_PORTAL = "1";
  };
}
