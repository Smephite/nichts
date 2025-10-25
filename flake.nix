{
  description = "My personal NixOS configuration";
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: {
    inherit (nixpkgs) lib;
    nixosConfigurations = import ./hosts {inherit inputs;};
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-nylon-wg.url = "github:smephite/nixpkgs/add-nylon-wg";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };  
  };
}