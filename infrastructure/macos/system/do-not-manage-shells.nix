{
  # pkgs,
  # self,
  ...
}: {
  # do not let nix darwin manage bashrc, zshrc, zshenv

  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/programs/bash/default.nix#L16
  programs.bash.enable = false;

  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/programs/zsh/default.nix#L19
  programs.zsh.enable = false;
}
