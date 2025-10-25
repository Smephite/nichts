{inputs, ...}:
let add_nylon_pr = final: prev: {
    inherit (inputs.nixpkgs-nylon-wg.legacyPackages.${prev.system})
      nylon-wg;
};
in
{
  nixpkgs.overlays = [
    add_nylon_pr
  ];
}