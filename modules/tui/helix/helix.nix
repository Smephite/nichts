{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.editors.helix;
  inherit (config.modules.system) username;
  inherit (lib) mkIf mkEnableOption;
in
{
  # this config (including languages.nix was largely taken from https://github.com/bloxx12/nichts)
  options.modules.programs.editors.helix.enable = mkEnableOption "helix";
  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.helix = {
        enable = true;
        package = inputs.helix.packages.${pkgs.system}.default;

        settings = {
          editor = {
            cursorline = true;
            color-modes = true;
            indent-guides.render = true;
            lsp.display-inlay-hints = true;
            line-number = "relative";
            true-color = true;
            auto-format = true;
            completion-timeout = 5;
            mouse = true;
            bufferline = "multiple";
            soft-wrap.enable = true;
            lsp.display-messages = true;
            cursor-shape = {
              insert = "bar";
            };
            statusline.left = [
              "spinner"
              "version-control"
              "file-name"
            ];
            /*
              inline-diagnostics = {
                cursor-line = "hint";
                other-lines = "error";
              };
            */
          };
          keys.normal = {
            "space".g = [
              ":new"
              ":insert-output ${pkgs.lazygit}/bin/lazygit"
              ":buffer-close!"
              ":redraw"
            ];
            esc = [
              "collapse_selection"
              "keep_primary_selection"
            ];
            A-H = "goto_previous_buffer";
            A-L = "goto_next_buffer";
            A-w = ":buffer-close";
            A-f = ":format";
          };
        };
      };
    };
  };
}
