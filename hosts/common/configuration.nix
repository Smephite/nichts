{ config, pkgs, ... }:

let
  username = config.modules.other.system.username;
in
{
  imports = [
    ../../options/common/pin-registry.nix
    ../../options/common/preserve-system.nix
    ../../options/desktop/fonts.nix
  ];


  # use zsh as default shell
  users.users.${username}.shell = pkgs.zsh;
  users.defaultUserShell = pkgs.zsh;

  services.locate = {
    enable = true;
    interval = "hourly";
    package = pkgs.plocate;
    localuser = null;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };

  modules = {

    programs = {
      foot.enable = true;
      foot.server = true;
      ranger.enable = true;
      nh.enable = true;

    };
  };


}
