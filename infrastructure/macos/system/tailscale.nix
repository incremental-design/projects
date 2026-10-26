{...}: {
  services.tailscale = {
    enable = true;
    overrideLocalDns = false; # access services on tailnet using <service>.ts.net
  };
}
# see: https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/tailscale.nix
# long term notes
#
# Oblivious DNS over HTTPS (ODoH): dns that is encrypted and not stored by the DNS provider. prevents
# your ISP from spying on your DNS requests.
#
# how to use:
#
# 1) separately configure DNS resolve to the ODoH provider - see: https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/dnscrypt-proxy.nix
# 2) configure tailscale exit node with VPN like mullvad or proton (proton will require extra config). Do NOT override local DNS (as it will be overridden by step 1)
#
# computer goes through default route to get to ODoH provider
# computer gets web address from ODoH provider
# computer goes through default route to get to web address

