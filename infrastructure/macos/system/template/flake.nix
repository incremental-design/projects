{
  description = ''
    nix-darwin configuration
  '';
  inputs = {
    infrastructure.url = "github:incremental-design/projects?dir=infrastructure"; # path to flake containing darwin modules
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # pin to nixpkgs 26.05
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin"; # pin to nixpkgs 26.05 for MacOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"; # support nix-darwin.lib.darwinSystem
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin"; # inject pinned nixpkgs into nix darwin
  };
  outputs = {
    nix-darwin,
    infrastructure,
    nixpkgs,
    ...
  }: let
    system = "aarch64-darwin";
  in {
    # sudo -H nix run nix-darwin/nix-darwin-26.05#darwin-rebuild --extra-experimental-features "nix-command flakes" -- build --flake ./.#default --show-trace
    # ---,--- ---------------------,---------------------------- -----------------------,--------------------------    ------------------,-------------------
    #    |                         |                                                    |                                                |
    #    '- run as root without    |                                                    |                                                |
    #       changing home dir      |                                                    |                                                |
    #                              '- download and run nix-darwin scripts in github     |                                                |
    #                                                                                   '- enable new nix commands and flake support     |
    #                                                                                      so that darwin-rebuild can read this flake    |
    #                                                                                                                                    '- build, but don't
    #                                                                                                                                       install the files
    #                                                                                                                                       in this darwin                                                                                                                               configuration
    darwinConfigurations.default = nix-darwin.lib.darwinSystem {
      inherit system;
      pkgs = import nixpkgs {inherit system;};

      /*
      nix injects the pkgs argument into the modules for you. see https://github.com/nix-darwin/nix-darwin/blob/15abb8c98f336cd8bd840d71059adebabe60bf04/flake.nix#L28
      */
      modules = with infrastructure.darwinModules;
        [
          packages
          security
          shells
        ]
        ++ [
          {
            nixpkgs.hostPlatform = system;
            # networking.hostName   # see https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/networking/default.nix#L45

            # do not let nix darwin manage nix
            # https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/nix/default.nix#L208
            nix.enable = false;

            # Used for backwards compatibility, please read the changelog before changing.
            # $ darwin-rebuild changelog
            system.stateVersion = 6;
          }
        ];
    };
  };
}
