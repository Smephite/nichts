{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.programs.fish;
  username = config.modules.system.username;
  gitPath = config.modules.system.gitPath;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    programs.fish.enable = true;

    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    programs.nix-index.enableFishIntegration = true;
    programs.command-not-found.enable = mkForce false;
    users.users.${username}.shell = pkgs.fish;

    environment = {
      systemPackages = [pkgs.nix-your-shell];
      shells = [pkgs.fish];
      pathsToLink = ["/share/fish"];
    };

    home-manager.users.${username} = mkIf config.modules.other.home-manager.enable {
      imports = [./hm.nix];
      modules.programs.fish = mkMerge [
        cfg
        {
          flakePath = lib.mkDefault gitPath;
          extraAliases = mkMerge [
            (mkIf (builtins.elem pkgs.bat config.environment.systemPackages) {cat = "bat --plain";})
            (mkIf (builtins.elem pkgs.eza config.environment.systemPackages) {
              ls = "eza --icons";
              la = "eza --icons -a";
              ll = "eza --icons -lha";
              l = "eza --icons -lha";
            })
            (mkIf (builtins.elem pkgs.zellij config.environment.systemPackages) {zj = "zellij";})
            (mkIf (builtins.elem pkgs.lazygit config.environment.systemPackages) {lg = "lazygit";})
            (mkIf (builtins.elem pkgs.neovim config.environment.systemPackages) {nv = "nvim";})
            (mkIf config.programs.nh.enable {
              rebuild = "nh os switch";
              update = "nh os switch --update";
            })
          ];
        }
      ];
    };
  };
}
