{
  description = "My personal NixOS configuration";
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    inherit (nixpkgs) lib;
    nixosConfigurations = import ./hosts {inherit inputs;};
    homeConfigurations = import ./homes {inherit inputs;};
    packages.${system} = import ./pkgs {inherit pkgs self;};
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-nylon-wg.url = "github:smephite/nixpkgs/add-nylon-wg";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "home-manager";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zed.url = "github:zed-industries/zed";

    claude-desktop = {
      url = "github:Reginleif88/claude-cowork-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nichts-unfree = {
      url = "git+ssh://git@github.com/Smephite/nichts-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
