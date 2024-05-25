{ inputs, outputs, ... }: 

let 
add_nur = self: super: {
  # nur-no-pkgs = import inputs.nur-no-pkgs { pkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; nurpkgs = inputs.nixpkgs.legacyPackages.${profile-config.system}; };
  nur = import inputs.nur { 
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; # .legacyPackages.${profile-config.system};
    nurpkgs = import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; #.legacyPackages.${profile-config.system};
  };
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

in
{
  nixpkgs.overlays = [
      add_nur
      add_custom_scripts
  ];
}
