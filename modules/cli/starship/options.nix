{lib, ...}:
with lib; {
  options.modules.programs.starship = {
    enable = mkEnableOption "starship";
    jj = mkOption {
      type = types.bool;
      default = false;
      description = "enable jj-vcs integration (disables built-in git modules)";
    };
  };
}
