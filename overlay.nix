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
  # Only applied when the nichts-unfree input is accessible (private repo).
  # Hosts without SSH access to the private repo simply omit this overlay.
  add_unfree_pkgs =
    if builtins.hasAttr "nichts-unfree" inputs
    then inputs.nichts-unfree.overlays.default
    else _final: _prev: {};
in {
  nixpkgs.overlays = [
    add_nylon_pr
    add_zed
    add_claude_code
    add_local_pkgs
    add_unfree_pkgs
  ];
}
