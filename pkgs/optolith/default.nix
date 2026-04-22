{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  electron,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  sass,
  optolith-data ?
    builtins.fetchGit {
      url = "git@github.com:Smephite/optolith-data.git";
      rev = "6c082fb86bb6736427b4d145d607499aef9fe0e6";
    },
}:
buildNpmPackage rec {
  pname = "optolith";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "elyukai";
    repo = "optolith-client";
    rev = "0dc6316b5b04ea863c76f437faa1a4c3b99d4594";
    hash = "sha256-8Xv5oGgOWCnSH01xgJLSi8wl6HIhIlvmVyCvRr4FYUg=";
  };

  npmDepsHash = "sha256-uoqa1U8EgcTOA0prmwb4oPOHmaRcgLj5YCP0KeFw5xQ=";

  desktopItems = [
    (makeDesktopItem {
      name = "optolith";
      desktopName = "Optolith Insider";
      comment = meta.description;
      exec = "optolith %U";
      icon = "optolith";
      categories = ["Game"];
      startupWMClass = "Optolith";
    })
  ];

  nativeBuildInputs = [makeWrapper copyDesktopItems sass];

  # Skip postinstall scripts that try to download Electron or platform-native
  # binaries — Electron is provided by nixpkgs.
  npmFlags = ["--ignore-scripts"];

  postPatch = ''
    # Populate the database submodule (expected at app/Database by webpack
    # config and the runtime loader).
    cp -r ${optolith-data}/. app/Database/
  '';

  buildPhase = ''
    runHook preBuild

    # 1. Compile TypeScript (required before webpack picks up the .js output
    #    for some re-exported modules, but ts-loader handles most of it).
    #    Skip tsc type-check to avoid needing the full TS toolchain separately;
    #    ts-loader with transpileOnly:true covers the actual compilation.

    # 2. Compile SCSS -> app/main.css
    sass --style=compressed src/Main.scss app/main.css

    # 3. Bundle JS with webpack (ts-loader is invoked inline)
    NODE_ENV=production npm run js:build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    local appdir="$out/lib/optolith"
    mkdir -p "$appdir"

    # Webpack outputs main.js, renderer.js, and vendor chunks directly into app/
    # The full app/ directory is the Electron app root.
    cp -r app "$appdir/app"

    # Runtime node_modules needed by the main/renderer processes. Only the
    # production dependencies are required; devDependencies are build-time only.
    # We copy the whole node_modules since several packages are lazily required
    # at runtime and it is hard to enumerate them all.
    cp -r node_modules "$appdir/node_modules"

    cp package.json "$appdir/"
    cp CHANGELOG.md LICENSE "$appdir/" 2>/dev/null || true

    # Install icon
    install -Dm644 app/icon.png "$out/share/icons/hicolor/256x256/apps/optolith.png"

    # Launcher wrapper — Electron's app root is the directory containing
    # package.json (i.e. $appdir), which also contains app/main.js.
    mkdir -p "$out/bin"
    makeWrapper ${electron}/bin/electron "$out/bin/optolith" \
      --add-flags "$appdir" \
      --add-flags "--js-flags='--stack-size=65536'"

    runHook postInstall
  '';

  meta = {
    description = "Character generator for The Dark Eye (Das Schwarze Auge) 5th edition";
    homepage = "https://optolith.app";
    license = lib.licenses.mpl20;
    mainProgram = "optolith";
    platforms = lib.platforms.linux;
  };
}
