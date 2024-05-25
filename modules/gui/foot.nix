{
    config,
    inputs,
    lib,
    pkgs,
    ...
}: with lib; let
    cfg = config.modules.programs.foot;
    username = config.modules.other.system.username;
in {
    options.modules.programs.foot = {
        enable = mkEnableOption "foot";
        server = mkEnableOption "foot server mode";
    };

    config = mkIf cfg.enable {
        environment.sessionVariables = {
            TERM = "foot";
        };
        home-manager.users.${username} = {
            programs.foot = {
                enable = true;
                server.enable = cfg.server;
            };
        };
    };
}
