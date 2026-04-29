{lib, ...}:
with lib; {
  options.modules.programs.fish = {
    enable = mkEnableOption "fish";
    flakePath = mkOption {
      type = types.str;
      default = "";
      description = "path to the flake directory, used for the 'flake' abbr";
    };
    extraAliases = mkOption {
      type = types.attrs;
      default = {};
      description = "extra shell abbreviations";
    };
  };
}
