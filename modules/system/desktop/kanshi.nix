{
  lib,
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

  mkKanshiOutput = m: {
    criteria =
      if m.device != null
      then m.device
      else if m.serial != null
      then "* ${m.model} ${m.serial}"
      else "* ${m.model} *";
    mode = "${toString m.resolution.x}x${toString m.resolution.y}@${toString m.refresh_rate}Hz";
    position = "${toString m.position.x},${toString m.position.y}";
    scale = m.scale;
    transform = kanshiTransform m.transform;
  };

  mkKanshiProfile = _name: monitors: {
    outputs = map mkKanshiOutput monitors;
  };
in {
  config = lib.mkIf (wlrWmActive && hasProfiles) {
    home-manager.users.${username} = {
      services.kanshi = {
        enable = true;
        settings =
          lib.mapAttrsToList (name: monitors: {
            profile = {
              name = name;
              outputs = (mkKanshiProfile name monitors).outputs;
            };
          })
          resolved;
      };
    };
  };
}
