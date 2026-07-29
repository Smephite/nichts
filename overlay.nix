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
  add_llm_agents = final: prev: let
    agents = (inputs.llm-agents.overlays.shared-nixpkgs final prev).llm-agents;
  in {
    inherit (agents) claude-code claude-desktop herdr;
  };
  add_local_pkgs = final: prev:
    import ./pkgs {
      pkgs = final;
      self = inputs.self;
    };
  fix_pandas_stubs = final: prev: {
    python3Packages = prev.python3Packages.override {
      overrides = pfinal: pprev: {
        pandas-stubs = pprev.pandas-stubs.overridePythonAttrs {
          doCheck = false;
          pythonImportsCheck = [];
        };
      };
    };
  };
in {
  nixpkgs.overlays = [
    add_nylon_pr
    add_zed
    add_llm_agents
    add_local_pkgs
    fix_pandas_stubs
  ];
}
