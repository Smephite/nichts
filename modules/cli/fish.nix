{
    inputs,
    config,
    lib,
    pkgs,
    ...
}: with lib; let
    cfg = config.modules.programs.fish;
    username = config.modules.other.system.username;
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

        nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
        programs.nix-index = {
            enable = true;
            enableFishIntegration = true;
        };
        programs.command-not-found.enable = lib.mkForce false;
        users.users.${username}.shell = pkgs.fish;


        environment = {
            shells = [ pkgs.fish ];
            pathsToLink = [ "/share/fish" ];
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
                  shellAbbrs = lib.mkMerge[{
                      rebuild = "nh os switch";
                      update = "nh os switch --update";
                      cl = "clear";
                      cp = "cp -ivr";
                      mv = "mv -iv";
                      ls = "eza -a --icons";
                      nv = "nvim";
                      flake = "cd ${config.modules.other.system.gitPath}";
                      gpl = "curl https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE";
                      agpl = "curl https://www.gnu.org/licenses/agpl-3.0.txt -o LICENSE";
                  } cfg.extraAliases ];
              };
            # TODO: move this somewhere else
            programs.foot.settings.main.shell = lib.mkDefault "${pkgs.fish}/bin/fish";
        };
    };
}
