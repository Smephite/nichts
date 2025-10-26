{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption mkEnableOption types mapAttrs' optionalAttrs;
  username = config.modules.system.username;
  cfg = config.modules.programs.firefox;
  _extensionDefault = {
    installation_mode = "force_installed";
  };
  mkFirefoxExtension = id: attr:
    lib.nameValuePair id 
    (
      _extensionDefault //
      (
      optionalAttrs (builtins.isString attr)
        (
          { install_url = attr;} //
          (optionalAttrs ((builtins.match "^https?://.*" attr) == null) { install_url = "https://addons.mozilla.org/firefox/downloads/latest/${attr}/latest.xpi";})
        )
      ) //
      (
      optionalAttrs (builtins.isAttrs attr)
        (
          { install_url = attr.source;} //
          (optionalAttrs ((builtins.match "^https?://.*" attr.source) == null) { install_url = "https://addons.mozilla.org/firefox/downloads/latest/${attr.source}/latest.xpi";})
          // attr
        )
      )
    );
in {
  options.modules.programs.firefox = {
    enable = mkEnableOption "firefox";
    extensions = mkOption {
      description = "firefox extensions (formatted as { name = id; } attrset)";
      type = types.attrs;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.firefox = {
        enable = true;
        profiles = {
          main = {
            id = 0;
            isDefault = true;
            search.default = "ddg";
            userChrome = ''
              @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"); /* set default namespace to XUL */

              //#TabsToolbar {visibility: collapse; !important; }
              /* #navigator-toolbox {visibility: collapse;} */
              //browser {margin-right: -14px; margin-bottom: -14px; !important; }
            '';
            search.force = true;
            settings = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "media.ffmpeg.vaapi.enabled" = true; # enable hardware accelerated video playback (vaapi)
              "media.peerconnection.enabled" = false;
              "browser.newtabpage.activity-stream.showSponsored" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            };
            containersForce = true;
            containers = {
              nix = {
                color = "blue";
                icon = "circle";
                id = 0;
              };
              dangerous = {
                color = "red";
                icon = "fruit";
                id = 1;
              };
              shopping = {
                color = "yellow";
                icon = "cart";
                id = 2;
              };
              video = {
                color = "pink";
                icon = "vacation";
                id = 3;
              };
              studying = {
                color = "green";
                icon = "fence";
                id = 4;
              };
            };
          };
        };

        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          DisableAccounts = true;
          DisableFirefoxScreenshots = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = true;
          DisplayBookmarksToolbar = "always"; # alternatives: "always" or "newtab"
          DisplayMenuBar = "always"; # alternatives: "always", "never" or "default-on"
          SearchBar = "unified"; # alternative: "separate"
          FirefoxSuggest = {
            WebSuggestions = true;
            ImproveSuggest = true;
            Locked = true;
          };
          SearchSuggestEnabled = true;
          theme = {
            colors = {
              background-darker = "181825";
              background = "1e1e2e";
              foreground = "cdd6f4";
            };
          };

          OfferToSaveLogins = false;
          font = "Lexend";
          ExtensionSettings = mapAttrs' mkFirefoxExtension cfg.extensions;
        };
      };
    };
  };
}
