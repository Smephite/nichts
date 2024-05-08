{ inputs, outputs, ... }: 

let 
add_nur = self: super: {
  # nur-no-pkgs = import inputs.nur-no-pkgs { pkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; nurpkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; };
  nur = import inputs.nur { 
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; # .legacyPackages.${profile-config.system};
    nurpkgs = import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; #.legacyPackages.${profile-config.system};
  };
};
add_catppuccin_wallpapers = self: super: {
  catppuccin-wallpapers = super.fetchFromGitHub {
    owner = "zhichaoh";
    repo = "catppuccin-wallpapers";
    rev = "1023077979591cdeca76aae94e0359da1707a60e"; 
    sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
  };

};
in
{
  nixpkgs.overlays = [
      add_nur
      add_catppuccin_wallpapers
  ];
}
