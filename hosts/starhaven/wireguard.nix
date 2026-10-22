{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  # WireGuard link from starhaven to the UniFi Cloud Gateway.
  #
  # UniFi exposes WireGuard under "VPN Server" (its Site-to-Site section only
  # does IPsec/OpenVPN), so starhaven is the dialing client rather than a
  # symmetric peer. Same result: one direct tunnel, with only the home LAN
  # routed over it.
  #
  # Every tunnel parameter -- address, private key, peer key, endpoint, routed
  # subnets -- lives inside the encrypted wg.unifi.age blob, not in this file,
  # because this repo is public. networking.wireguard would inline all of it
  # into the world-readable nix store, so wg-quick gets a config file instead:
  # configFile is typed as a plain string, so the path is interpolated rather
  # than copied into the store, and the unit sets PrivateTmp so its working
  # copy during activation isn't exposed either.
  #
  # Replaces nylon's "old_dmz" service. The nylon mesh stays up for
  # c2/c3/silverwind and is untouched: separate interface, separate UDP port.

  age.secrets.wg-unifi = {
    file = "${self}/secrets/wg.unifi.age";
  };

  networking.firewall.allowedUDPPorts = [51820];
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.enable = true;

  # The LAN side may initiate toward starhaven, not just the reverse. Together
  # with PersistentKeepalive in the tunnel config this keeps the link usable
  # both ways even though starhaven is nominally the client. Narrow this to
  # explicit ports if you later want the LAN to reach only specific services.
  networking.firewall.trustedInterfaces = ["wg0"];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.wg-quick.interfaces.wg0 = {
    configFile = config.age.secrets.wg-unifi.path;
    autostart = true;
  };

  # The wg-quick module copies configFile to /tmp/wg0.conf (PrivateTmp) so the
  # interface gets its name, and runs `wg-quick down` against that copy on
  # stop. systemd's tmp cleaner ages the copy out after 10 days - the private
  # dir is excluded from cleaning, its contents are not - so the first restart
  # after that (any nixos-rebuild) fails: down finds no file and leaves wg0
  # up, up then refuses because wg0 exists, and the LAN routes are gone.
  # Bit starhaven on 2026-09-30. Re-copy before down, and clear a leftover
  # interface before up.
  systemd.services.wg-quick-wg0 = {
    preStop = lib.mkBefore "cp ${config.age.secrets.wg-unifi.path} /tmp/wg0.conf";
    preStart = lib.mkAfter "${pkgs.iproute2}/bin/ip link del wg0 2>/dev/null || true";
  };

  # No NAT on purpose: this is a routed tunnel and both ends know each other's
  # addresses. (The previous config masqueraded everything leaving eth0, which
  # belonged to a different, internet-gateway setup.)
}
