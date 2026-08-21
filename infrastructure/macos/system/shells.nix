{pkgs, ...}: {
  environment.shells = with pkgs; [
    bashInteractive
    zsh
    nushell
  ];
  fonts.packages = with pkgs; [nerd-fonts.lilex];

  # use the bash and zsh that nix provides over the builtin /bin/bash and /bin/zsh
  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/programs/bash/default.nix#L16
  programs.bash.enable = true;

  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/programs/zsh/default.nix#L19
  programs.zsh.enable = true;
}
