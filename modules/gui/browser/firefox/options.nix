{lib, ...}:
with lib; {
  options.modules.programs.firefox = {
    enable = mkEnableOption "firefox";
    extensions = mkOption {
      description = "firefox extensions (formatted as { name = id; } attrset)";
      type = types.attrs;
      default = {};
    };
  };
}
