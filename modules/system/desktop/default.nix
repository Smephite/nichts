{
  config,
  ...
}:
  let desktops = with config.modules.system.desktop; [
    gnome.enable
    niri.enable
    kde.enable
  ];
in 
{
  imports = [
    ./cosmic.nix
    ./gnome.nix
    ./kde.nix
    ./niri.nix
    ./monitors.nix
  ];

  config = {
    assertions = [
      {
        assertion = ((builtins.length (builtins.filter (x: x) desktops)) <= 1);
        message = "Only one option from config.modules.sytem.desktop may be enabled at a time!";
      }
    ]; 
  };

}
