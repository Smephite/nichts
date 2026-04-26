{inputs, ...}: let
  add_nylon_pr = final: prev: {
    inherit
      (inputs.nixpkgs-nylon-wg.legacyPackages.${prev.stdenv.hostPlatform.system})
      nylon-wg
      ;
  };
  add_zed = final: prev: {
    zed-editor = inputs.zed.packages.${prev.stdenv.hostPlatform.system}.default;
  };
  add_claude_code = inputs.claude-code.overlays.default;
  add_local_pkgs = final: prev: import ./pkgs {pkgs = final;};
in {
  nixpkgs.overlays = [
    add_nylon_pr
    add_zed
    add_claude_code
    add_local_pkgs
  ];
}
