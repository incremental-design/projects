{
  # pkgs,
  self,
  ...
}: {
  # do not let nix darwin manage nix
  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/nix/default.nix#L208
  nix.enable = false;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
