{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.fish;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    home.packages = [pkgs.nix-your-shell];

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting
        nix-your-shell fish | source
      '';
      plugins = [
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        {
          name = "puffer";
          inherit (pkgs.fishPlugins.puffer) src;
        }
      ];
      shellAbbrs = mkMerge [
        {
          cat = mkIf config.programs.bat.enable "bat --plain";
          cl = "clear";
          cp = "cp -ivr";
          mv = "mv -iv";
          ls = mkIf config.programs.eza.enable "eza --icons";
          la = mkIf config.programs.eza.enable "eza --icons -a";
          ll = mkIf config.programs.eza.enable "eza --icons -lha";
          l = mkIf config.programs.eza.enable "eza --icons -lha";
          ns = "nix repl --expr 'import <nixpkgs>{}'";
          gpl = "curl https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE";
          agpl = "curl https://www.gnu.org/licenses/agpl-3.0.txt -o LICENSE";
        }
        (mkIf (cfg.flakePath != "") {flake = "cd \"${cfg.flakePath}\"";})
        cfg.extraAliases
      ];
    };
  };
}
