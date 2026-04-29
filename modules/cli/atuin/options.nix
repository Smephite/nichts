{lib, ...}:
with lib; {
  options.modules.programs.atuin.enable = mkEnableOption "atuin";
}
