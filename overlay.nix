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
  # playwright's prebuilt WPEWebKit links against libmanette-0.2.so.0, which is
  # missing from webkit.nix's inputs, so autoPatchelf fails and takes every
  # dependent down with it. radicle-desktop is the only thing here that pulls
  # the browser set in, and only as a build-time env var — its checkPhase runs
  # unit tests and linters, never a browser — so hand it a webkit-less set and
  # leave playwright itself alone. Drop once nixpkgs adds libmanette.
  fix_radicle_desktop_playwright = final: prev: {
    radicle-desktop = prev.radicle-desktop.overrideAttrs (old: {
      env =
        old.env
        // {
          PLAYWRIGHT_BROWSERS_PATH =
            prev.playwright-driver.passthru.selectBrowsers {withWebkit = false;};
        };
    });
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
    fix_radicle_desktop_playwright
    fix_pandas_stubs
  ];
}
