{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.tv7;
in {
  options.modules.services.tv7 = {
    enable = lib.mkEnableOption "firewall rules for TV7 multicast streams";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands = ''
      iptables -I nixos-fw -p udp -d 233.50.230.0/24 --dport 5000 -j nixos-fw-accept
      iptables -I nixos-fw -p udp -d 239.77.0.0/16   --dport 5000 -j nixos-fw-accept
      iptables -I nixos-fw -p igmp -j nixos-fw-accept
    '';
  };
}
