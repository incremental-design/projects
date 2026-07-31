{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    /*
    all pkgs
    */
    git
    starship
    nix-direnv
    /*
    nushell
    */
    nushell
    nushell-plugin-bson
    nushell-plugin-formats
    nushell-plugin-gstat
    nushell-plugin-hcl
    nushell-plugin-highlight
    nushell-plugin-polars
    nushell-plugin-query
    nushell-plugin-semver
    nushell-plugin-skim
    /*
    packages for zsh, bash
    */
    bashInteractive
    zsh
    jq
    yq-go
    glow
    fx
    htop
  ];
}
