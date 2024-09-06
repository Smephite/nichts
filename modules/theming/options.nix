{ config, lib, ... }: 

with lib;
let 
  username = config.modules.other.system.username;
  cfg = config.modules.theming;
{
  options.modules.theming.theme = mkOption {
    type = with types; nullOr (
      enum [ "catppuccin" ]
    );
    default = null;
    example = "catppuccin";
    description = "Select which system wide theme to use";
  };

  imports = [ ./base ] ++ 
            lists.optionals cfg.theme != null "./${cfg.theme}"
}
