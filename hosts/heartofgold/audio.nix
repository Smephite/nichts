{pkgs, ...}: let
  cardName = "alsa_card.pci-0000_01_00.1";
  denonSink = "alsa_output.pci-0000_01_00.1.pro-output-3";
  monitorSink = "alsa_output.pci-0000_01_00.1.pro-output-7";
  unusedSinks = [
    "alsa_output.pci-0000_01_00.1.pro-output-8"
    "alsa_output.pci-0000_01_00.1.pro-output-9"
  ];
in {
  services.pipewire.wireplumber.extraConfig."51-hdmi-multi-output" = {
    "monitor.alsa.rules" = [
      {
        matches = [{"device.name" = cardName;}];
        actions.update-props = {
          "api.acp.auto-profile" = false;
          "device.profile" = "pro-audio";
        };
      }
      {
        matches = [{"node.name" = denonSink;}];
        actions.update-props = {
          "node.description" = "Denon AVR";
          "node.nick" = "Denon";
        };
      }
      {
        matches = [{"node.name" = monitorSink;}];
        actions.update-props = {
          "node.description" = "M34WQ Monitor";
          "node.nick" = "Monitor";
        };
      }
      {
        matches = map (n: {"node.name" = n;}) unusedSinks;
        actions.update-props."node.disabled" = true;
      }
    ];
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "sink-denon";
      runtimeInputs = [pkgs.pulseaudio];
      text = ''
        pactl set-default-sink ${denonSink}
        echo "Default sink → Denon AVR"
      '';
    })
    (pkgs.writeShellApplication {
      name = "sink-monitor";
      runtimeInputs = [pkgs.pulseaudio];
      text = ''
        pactl set-default-sink ${monitorSink}
        echo "Default sink → M34WQ Monitor"
      '';
    })
  ];
}
