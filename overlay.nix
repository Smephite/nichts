{inputs, ...}: let
  add_nylon_pr = final: prev: {
    inherit
      (inputs.nixpkgs-nylon-wg.legacyPackages.${prev.system})
      nylon-wg
      ;
  };
  add_librepods_pr = final: prev: {
    librepods = inputs.nixpkgs-librepods.legacyPackages.${prev.system}.librepods.overrideAttrs (_: rec{
    #  src = prev.fetchFromGitHub{
    #    owner = "kavishdevar";
    #    repo = "librepods";
    #    rev = "a01e16792a73deb34c5bd0c4aa019c496642ee71"; # linux/rust
    #    hash = "sha256-ZvHbSSW0rfcsNUORZURe0oBHQbnqmS5XT9ffVMwjIMU=";
    #  };
    });
    
  };
in {
  nixpkgs.overlays = [
    add_nylon_pr
    add_librepods_pr
  ];
}
