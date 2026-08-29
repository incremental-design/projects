{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    /*
    gnu replacements for bsd
    */
    coreutils
    findutils
    gnused
    gnugrep
    gawk
    gnutar
    gzip
    /*
    all pkgs
    */
    starship
    nix-direnv
    /*
    nushell
    */
    nushell
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
