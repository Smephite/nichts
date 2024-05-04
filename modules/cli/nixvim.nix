{ inputs, lib, config, pkgs, ... }: 

let 
  cfg = config.modules.programs.nixvim;
  username = config.modules.other.system.username;
in
{
  options.modules.programs.nixvim.enable = lib.mkEnableOption "nixvim";
  
  imports = [ 
    inputs.nixvim.nixosModules.nixvim 
  ];

  config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        ripgrep
        lazygit
      ];

      programs.nixvim = {
        enable = true;
        colorschemes.catppuccin.enable  = true;
        plugins = {
          treesitter.enable = true;
          typst-vim.enable = true;
          rust-tools.enable = true;
          jupytext.enable = true;
          julia-cell.enable = true;
          neo-tree.enable = true;
          # lazygit.enable = true;
          # lsp.rust-analyzer.enable = true;
        };

        extraPlugins = with pkgs.vimPlugins; [
          vim-nix
        ];
      };
    };
}
