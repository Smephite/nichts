{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.starship;
  jj = cfg.jj;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable or false;
      enableBashIntegration = true;

      settings = {
        git_status.disabled = mkIf jj (mkForce false);
        git_commit.disabled = mkIf jj (mkForce false);
        git_metrics.disabled = mkIf jj (mkForce false);
        git_branch.disabled = mkIf jj (mkForce false);
        cmd_duration.min_time = 5000;
        format = mkIf jj ''
          $all''${custom.git_branch}''${custom.git_commit}''${custom.git_metrics}''${custom.git_status}
        '';
        custom = {
          jj = mkIf jj {
            description = "The current jj status";
            when = "jj --ignore-working-copy root";
            symbol = "[](bold blue) ";
            command = ''
              jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
                separate(" ",
                  change_id.shortest(4),
                  bookmarks,
                  "|",
                  concat(
                    if(conflict, "💥"),
                    if(divergent, "🚧"),
                    if(hidden, "👻"),
                    if(immutable, "🔒"),
                  ),
                  raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
                  raw_escape_sequence("\x1b[1;32m") ++ coalesce(
                    truncate_end(29, description.first_line(), "…"),
                    "∅",
                  ) ++ raw_escape_sequence("\x1b[0m"),
                )
              '
            '';
          };
          git_status = mkIf jj {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_status";
            style = "";
            description = "Only show git_status if we're not in a jj repo";
          };
          git_commit = mkIf jj {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_commit";
            style = "";
            description = "Only show git_commit if we're not in a jj repo";
          };
          git_metrics = mkIf jj {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_metrics";
            style = "";
            description = "Only show git_metrics if we're not in a jj repo";
          };
          git_branch = mkIf jj {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_branch";
            style = "";
            description = "Only show git_branch if we're not in a jj repo";
          };
        };
        add_newline = false;
        command_timeout = 1000;
        line_break.disabled = false;
        directory = {
          truncation_length = 3;
          truncate_to_repo = false;
          truncation_symbol = "[…]/";
        };
        c.symbol = " ";
        directory.read_only = " 󰌾";
        git_branch.symbol = " ";
        haskell.symbol = " ";
        hostname.ssh_symbol = " ";
        java.symbol = " ";
        kotlin.symbol = " ";
        meson.symbol = "󰔷 ";
        nix_shell.symbol = " ";
        package.symbol = "󰏗 ";
        rust.symbol = " ";
      };
    };
  };
}
