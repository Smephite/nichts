{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.programs.starship;
  username = config.modules.system.username;
  jj = config.modules.programs.jj.enable or false;
in {
  options.modules.programs.starship.enable = mkEnableOption "starship";

  config = mkIf cfg.enable {
    
    assertions = 
      [
        {
          assertion = config.modules.system.fonts.enable;
          message = "modules.programs.starship requires modules.system.fonts to be enabled";
        }
      ];

    home-manager.users.${username} = {
      programs.starship = {
        enable = true;
        enableFishIntegration = config.modules.programs.fish.enable or false;
        enableZshIntegration = config.modules.programs.zsh.enable or false;

        settings = {
          git_status.disabled = mkIf jj (lib.MkForce false); # makes everything slow when jj is in use
          git_commit.disabled = mkIf jj (lib.MkForce false);
          git_metrics.disabled = mkIf jj (lib.MkForce false);
          git_branch.disabled = mkIf jj (lib.MkForce false);
          cmd_duration.min_time = 5000;
          format = mkIf jj ''
            $all''${custom.git_branch}''${custom.git_commit}''${custom.git_metrics}''${custom.git_status}
          '';
          # taken from https://github.com/jj-vcs/jj/wiki/Starship
          custom = {
            # custom module for jj status
            # note that you'll need to add ${custom.git_branch}, ${custom.git_commit} etc
            # into format: https://starship.rs/config/#default-prompt-format
            jj = mkIf jj {
              description = "The current jj status";
              when = "jj --ignore-working-copy root";
              symbol = "[](bold blue) ";
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
              style = ""; # This disables the default "(bold green)" style
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
              description = "Only show git_metrics if we're not in a jj repo";
              style = "";
            };
            git_branch = mkIf jj {
              when = "! jj --ignore-working-copy root";
              command = "starship module git_branch";
              description = "Only show git_branch if we're not in a jj repo";
              style = "";
            };
          };
          add_newline = false;
          command_timeout = 1000;
          line_break = {
            disabled = false;
          };
          directory = {
            truncation_length = 3;
            truncate_to_repo = false;
            truncation_symbol = "[…]/";
          };
          c.symbol = " ";
          directory.read_only = " 󰌾";
          git_branch.symbol = " ";
          haskell.symbol = " ";
          hostname.ssh_symbol = " ";
          java.symbol = " ";
          kotlin.symbol = " ";
          meson.symbol = "󰔷 ";
          nix_shell.symbol = " ";
          package.symbol = "󰏗 ";
          rust.symbol = " ";
        };
      };
    };
  };
}