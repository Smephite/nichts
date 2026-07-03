{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.tmux;

  oh-my-tmux = pkgs.fetchFromGitHub {
    owner = "gpakosz";
    repo = ".tmux";
    rev = "af33f07134b76134acca9d01eacbdecca9c9cda6";
    hash = "sha256-nXm664l84YSwZeRM4Hsweqgz+OlpyfwXcgEdyNGhaGA=";
  };

  localConf = pkgs.writeText "tmux.conf.local" ''
    # source oh-my-tmux defaults
    source-file ${oh-my-tmux}/.tmux.conf.local

    # highlight focused pane
    tmux_conf_theme_highlight_focused_pane=true

    # pane borders
    tmux_conf_theme_pane_border_style=fat
    tmux_conf_theme_pane_border="#808080"

    # mouse mode
    set -g mouse on
  '';
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    home.packages = [pkgs.tmux];

    # oh-my-tmux: .tmux.conf is the framework, .tmux.conf.local holds overrides
    home.file.".tmux.conf".source = "${oh-my-tmux}/.tmux.conf";
    home.file.".tmux.conf.local".source = localConf;

    # reload tmux config after home-manager activation
    home.activation.reloadTmux = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.tmux}/bin/tmux source-file ~/.tmux.conf 2>/dev/null || true
    '';
  };
}
