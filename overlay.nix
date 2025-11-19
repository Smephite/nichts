{inputs, ...}: let
  add_nylon_pr = final: prev: {
    inherit
      (inputs.nixpkgs-nylon-wg.legacyPackages.${prev.system})
      nylon-wg
      ;
  };
  add_librepods_pr = final: prev: {
    inherit
      (inputs.nixpkgs-librepods.legacyPackages.${prev.system})
      librepods
      ;
  };
in {
  nixpkgs.overlays = [
    add_nylon_pr
    add_librepods_pr
  ];
}
