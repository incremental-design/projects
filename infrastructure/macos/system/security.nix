{
  # pkgs,
  # self,
  ...
}: {
  # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/security/pam.nix#L14
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };
}
