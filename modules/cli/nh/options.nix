{lib, ...}:
with lib; {
  options.modules.programs.nh = {
    enable = mkEnableOption "nh";
    flakePath = mkOption {
      type = types.str;
      default = "";
      description = "path to the flake directory";
    };
    trustedSigningKeys = mkOption {
      type = types.listOf (types.either types.path types.str);
      default = [];
      description = "SSH public keys (path to .pub file or raw key string) trusted for nh os verification";
    };
  };
}
