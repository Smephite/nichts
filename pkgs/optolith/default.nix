{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  nodejs_22,
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
}: let
  src = fetchFromGitHub {
    owner = "elyukai";
    repo = "optolith-client";
    rev = "0dc6316b5b04ea863c76f437faa1a4c3b99d4594";
    hash = "sha256-8Xv5oGgOWCnSH01xgJLSi8wl6HIhIlvmVyCvRr4FYUg=";
  };

  # Apply the electron41-compat patch and then strip deploy-only devDependencies
  # that pull in native addons (ssh2-sftp-client -> cpu-features/NAN,
  # electron-builder, electron-notarize). These are only needed by the deploy/
  # scripts which are never run in the Nix build.
  #
  # We do this in a separate derivation so that the patched package-lock.json is
  # the one that fetchNpmDeps hashes against.
  patchedSrc =
    runCommand "optolith-src-patched" {
      inherit src;
      nativeBuildInputs = [nodejs_22];
      patches = [
        ./electron41-compat.patch
      ];
    } ''
      cp -r "$src" "$out"
      chmod -R u+w "$out"

      cd "$out"

      for p in $patches; do
        patch -p1 < "$p"
      done

      node - <<'EOF'
      const fs = require("fs");
      const drop = ["ssh2-sftp-client", "electron-builder", "electron-notarize"];

      const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
      drop.forEach(d => delete pkg.devDependencies[d]);
      fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));

      const lock = JSON.parse(fs.readFileSync("package-lock.json", "utf8"));
      drop.forEach(d => {
        delete lock.dependencies?.[d];
        delete lock.packages?.["node_modules/" + d];
      });
      fs.writeFileSync("package-lock.json", JSON.stringify(lock, null, 2));
      EOF
    '';
in
  buildNpmPackage {
    pname = "optolith";
    version = "1.5.2";

    src = patchedSrc;

    # Regenerate after any change to patchedSrc / package-lock.json:
    #   nix build .#optolith 2>&1 | grep 'got:' | awk '{print $2}'
    npmDepsHash = "sha256-0JgSjXQ52lEFGmUcpoxQcyxFWhRzDM96Cy+maUOF+Pk=";

    nodejs = nodejs_22;

    nativeBuildInputs = [makeWrapper copyDesktopItems sass];

    npmFlags = ["--legacy-peer-deps"];

    env = {
      # Do not download the Electron binary – we use the one from nixpkgs.
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    };

    postPatch = ''
      # Populate the database submodule (expected at app/Database by webpack
      # config and the runtime loader).
      cp -r ${optolith-data}/. app/Database/
    '';

    # The upstream "build" script calls tsc first (noEmit = true) which exits
    # non-zero due to pre-existing type mismatches in the repo. Skip tsc and
    # invoke the two real build steps directly:
    #   • webpack  (transpileOnly = true → no type errors)
    #   • sass
    npmBuildScript = null;

    buildPhase = ''
      runHook preBuild

      npm run js:build
      npm run css:build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # Copy the fully built app/ directory (JS bundles, CSS, assets,
      # game data, fonts, images, icons, index.html …)
      install -dm755 $out/lib/optolith
      cp -r app/. $out/lib/optolith/

      # Icons
      install -Dm644 app/icon256x256.png \
        $out/share/icons/hicolor/256x256/apps/optolith.png || true
      install -Dm644 app/icon.png \
        $out/share/icons/hicolor/128x128/apps/optolith.png

      # Launcher wrapper – use the NixOS-managed Electron binary so that
      # all shared libraries (glib, X11, …) are properly resolved.
      # Force native Wayland via ozone to avoid XWayland leaving modifier
      # keys (Shift etc.) stuck in the compositor after the app exits.
      makeWrapper ${electron}/bin/electron \
        $out/bin/optolith \
        --add-flags "$out/lib/optolith/main.js" \
        --add-flags "--no-sandbox" \
        --add-flags "--ozone-platform=wayland" \
        --add-flags "--enable-features=WaylandWindowDecorations"

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "optolith";
        desktopName = "Optolith";
        exec = "optolith %U";
        icon = "optolith";
        comment = "Hero generator for The Dark Eye";
        categories = ["Game" "RolePlaying"];
        terminal = false;
        type = "Application";
        startupWMClass = "Optolith";
      })
    ];

    meta = {
      description = "Character generator for The Dark Eye (Das Schwarze Auge) 5th edition";
      homepage = "https://optolith.app";
      license = lib.licenses.mpl20;
      mainProgram = "optolith";
      platforms = lib.platforms.linux;
    };
  }
