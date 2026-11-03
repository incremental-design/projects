{
  config,
  lib,
  ...
}: let
  tailscaleConfig = config.services.tailscale;
in {
  networking.applicationFirewall = {
    allowSigned = true;
    allowSignedApp = true;
    enableStealthMode = true;
  };
  networking.wakeOnLan.enable = true;
  # allow all incoming connections from airdrop and loopback
  environment.etc."pf.anchors/nix-darwin".text = {
    text = ''
      # allow airdrop, airplay, continuity
      pass quick on lo0 all
      pass quick on awdl0 all
      pass quick on llw0 all

      # allow mdns discovery
      pass quick inet proto udp from 224.0.0.0/4 to any port 5353

      # allow all outgoing connections
      pass out quick all keep state
      ${
        if tailscaleConfig.enable
        then ''
          # allow incoming connections from tailscale
          # https://tailscale.com/docs/reference/reserved-ip-addresses
          table <ts> { 100.64.0.0/10 100.100.0.0/24 100.100.100.0/24 100.100.100.100 100.115.92.0/23 fd7a:115c:a1e0::/48 fd7a:115c:a1e0::53 100.101.102.103 }
          pass quick inet from <ts> to any
          pass quick inet from any to <ts>
          pass quick inet6 any to <ts>

          # deny all other incoming connections
        ''
        else ''
          # deny incoming connections
        ''
      }
      block in all
    '';
    mode = "0644";
    owner = "root";
  };
  system.activationScripts.etc.text = lib.mkAfter ''
    sudo pfctl -a com.apple/nix-darwin -f /etc/pf.anchors/nix-darwin
  '';
}
