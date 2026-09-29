{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.system.desktop;
  username = config.modules.system.username;
  resolved = cfg._resolvedMonitors;

  wmCfg = cfg.wm;
  wlrWmActive =
    (wmCfg.cosmic.enable or false)
    || (wmCfg.niri.enable or false);

  hasProfiles = resolved != {};

  kanshiTransform = t:
    if t == 1
    then "90"
    else if t == 2
    then "180"
    else if t == 3
    then "270"
    else "normal";

  mkKanshiCriteria = m:
    if m.device != null
    then m.device
    else let
      mfr =
        if m.manufacturer != null
        then m.manufacturer
        else "*";
      model =
        if m.model != null
        then m.model
        else "*";
      serial =
        if m.serial != null
        then m.serial
        else "*";
    in "${mfr} ${model} ${serial}";

  mkKanshiOutput = m: {
    criteria = mkKanshiCriteria m;
    mode = "${toString m.resolution.x}x${toString m.resolution.y}@${toString m.refresh_rate}Hz";
    position = "${toString m.position.x},${toString m.position.y}";
    scale = m.scale;
    transform = kanshiTransform m.transform;
  };

  mkKanshiProfile = _name: monitors: {
    outputs = map mkKanshiOutput monitors;
  };

  # Catch-all so an unknown monitor still lights up instead of leaving kanshi
  # with nothing to apply. Per kanshi(5) a plain `output "*"` matches exactly
  # one output, so a wildcard profile can never match a multi-monitor setup;
  # `...output` is the directive that takes any number of them. home-manager's
  # module only emits `output "<criteria>"` and its `extraConfig` escape hatch
  # is mutually exclusive with `settings`, so the fallback is written by hand
  # and pulled in with an include. Kanshi is first-match: this must come last.
  #
  # The fallback only enables outputs — it cannot position them, since the
  # directives after `...output` apply to every matched output alike. Add a
  # real profile to get a layout.
  fallbackConfig = pkgs.writeText "kanshi-fallback.conf" ''
    profile fallback {
    	...output "*" enable
    }
  '';
in {
  config = lib.mkIf (wlrWmActive && hasProfiles) {
    home-manager.users.${username} = {
      services.kanshi = {
        enable = true;
        settings =
          (lib.mapAttrsToList (name: monitors: {
              profile = {
                name = name;
                outputs = (mkKanshiProfile name monitors).outputs;
              };
            })
            resolved)
          ++ [{include = "${fallbackConfig}";}];
      };
    };
  };
}
