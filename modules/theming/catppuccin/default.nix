{ inputs, ... }:

{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };
  home-manager.users.${username} = {
    catppuccin = {
      enable = true;
      flavor = "mocha";
    };
    imports = [ 
      inputs.catppuccin.homeManagerModules.catppuccin 
    ];
  };
}
