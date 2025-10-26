{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.fish;
  username = config.modules.system.username;
  gitPath = config.modules.system.gitPath;
  inherit (lib) mkIf mkEnableOption mkOption types mkForce mkMerge getExe;
in {
  options.modules.programs.fish = {
    enable = mkEnableOption "fish";
    extraAliases = mkOption {
      type = types.attrs;
      description = "extra shell aliases";
      default = {};
    };
  };

  config = mkIf cfg.enable {
    programs.fish.enable = true;

    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    programs.nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.command-not-found.enable = mkForce false;
    users.users.${username}.shell = pkgs.fish;

    environment = {
      shells = [pkgs.fish];
      pathsToLink = ["/share/fish"];
    };

    home-manager.users.${username} = {
      programs.fish = {
        enable = true;
        interactiveShellInit = "set fish_greeting";
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
            rebuild = mkIf config.programs.nh.enable "nh os switch";
            update = mkIf config.programs.nh.enable  "nh os switch --update";
            cat = mkIf (builtins.elem pkgs.bat config.environment.systemPackages) "bat --plain";
            cl = "clear";
            cp = "cp -ivr";
            mv = "mv -iv";
            ls = mkIf (builtins.elem pkgs.eza config.environment.systemPackages) "eza --icons";
            la = mkIf (builtins.elem pkgs.eza config.environment.systemPackages) "eza --icons -a";
            ll = mkIf (builtins.elem pkgs.eza config.environment.systemPackages) "eza --icons -lha";
            l  = mkIf (builtins.elem pkgs.eza config.environment.systemPackages) "eza --icons -lha";
            zj = mkIf (builtins.elem pkgs.zellij config.environment.systemPackages) "zellij";
            lg = mkIf (builtins.elem pkgs.lazygit config.environment.systemPackages) "lazygit";
            ns = "nix repl --expr 'import <nixpkgs>{}'";
            nv = mkIf (builtins.elem pkgs.neovim config.environment.systemPackages) "nvim";
            gpl = "curl https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE";
            agpl = "curl https://www.gnu.org/licenses/agpl-3.0.txt -o LICENSE";
            flake = "cd \"${gitPath}\"";
          }
          cfg.extraAliases
        ];
      };
    };
  };
}
