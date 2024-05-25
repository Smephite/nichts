{
    config,
    inputs,
    lib,
    pkgs,
    ...
}: with lib; let
    cfg = config.modules.programs.ranger;
    username = config.modules.other.system.username;
in {
    options.modules.programs.ranger.enable = mkEnableOption "ranger";

    config = mkIf cfg.enable {
        home-manager.users.${username} = {
            programs.ranger = {
                enable = true;
                settings = {
                  preview_images = true;
                  preview_images_method = "sixel";
                };
            };
        };
    };
}
