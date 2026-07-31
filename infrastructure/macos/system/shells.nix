{pkgs, ...}: {
  environment.shells = with pkgs; [
    bashInteractive
    zsh
    nushell
  ];
  fonts.packages = with pkgs; [nerd-fonts.zed-mono];
}
