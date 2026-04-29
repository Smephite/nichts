{lib, ...}:
with lib; {
  options.modules.programs.zed = {
    enable = mkEnableOption "Zed editor configuration";
    withPackage = mkOption {
      type = types.bool;
      default = true;
      description = "add zed-editor to home.packages (set false when installed system-wide)";
    };
  };
}
