{lib, ...}:
with lib; {
  options.modules.programs.tmux = {
    enable = mkEnableOption "tmux";
  };
}
