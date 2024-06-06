{ pkgs, lib, config, ... }: 

with lib;
let
  cfg = config.modules.login.greetd;
  session = config.modules.login.session;
in
{
  options.modules.login.greetd.enable = mkEnableOption "lightdm";
  #TODO: move somewhere else
  options.modules.login.session = mkOption {
    type = types.str;
  };


  config = mkIf cfg.enable {
    # login manager
    services.greetd = {
        enable = true;
    };
  };

}
