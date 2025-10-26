{ inputs, pkgs-local, ... }:
let
  add_nur = self: super: {
    # nur-no-pkgs = import inputs.nur-no-pkgs { pkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; nurpkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; };
    nur = import inputs.nur {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      }; # .legacyPackages.${profile-config.system};
      nurpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      }; # .legacyPackages.${profile-config.system};
    };
  };

  add_nixpkgs_small = self: super: rec {
    small = import inputs.nixpkgs-small { system = super.system; };
  };

  add_custom_scripts = self: super: {
    ani-cli-advanced = super.writeShellApplication {
      name = "ani-cli-advanced";
      runtimeInputs = with super; [ ani-cli ];
      text = ''
        selection=$(printf "\\ueacf Continue\n\\uf002 Search\n\\uea81 Delete History" | rofi -p "ani-cli" -dmenu -i)
        case $selection in
          *Search) ani-cli --rofi;;
          *Continue) ani-cli --rofi -c;;
          "*Delete History") ani-cli -D;;
        esac

      '';
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
    add_custom_scripts
    add_catppuccin_wallpapers
    add_nixpkgs_small
    (self: super: {
        nylon-wg = pkgs-local.nylon-wg;
    })
  ];
}
