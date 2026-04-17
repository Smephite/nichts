{ inputs, ... }:
let
  add_nylon_pr = final: prev: {
    inherit (inputs.nixpkgs-nylon-wg.legacyPackages.${prev.stdenv.hostPlatform.system})
      nylon-wg
      ;
  };
  add_zed_fork = final: prev: {
    zed-editor = inputs.zed-fork.packages.${prev.stdenv.hostPlatform.system}.default;
  };
  add_claude_desktop = final: prev: {
    claude-desktop =
      inputs.claude-desktop.packages.${prev.stdenv.hostPlatform.system}.claude-desktop-with-fhs;
  };
  add_claude_code = inputs.claude-code.overlays.default;
  add_local_pkgs = final: prev: import ./pkgs { pkgs = final; };
in
{
  nixpkgs.overlays = [
    add_nylon_pr
    #add_zed_fork
    add_claude_desktop
    add_claude_code
    add_local_pkgs
  ];
}
