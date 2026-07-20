{
  # pkgs,
  self,
  ...
}: {
  # Set Git commit hash for darwin-version.
  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/system/version.nix#L125
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/system/version.nix#L34
  system.stateVersion = 6;
}
