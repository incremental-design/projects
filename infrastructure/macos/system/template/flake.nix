{
  description = ''
    nix-darwin configuration
  '';
  inputs = {
    infrastructure.url = "github:incremental-design/projects?ref=make-infrastructure-darwin-install&dir=infrastructure";  # path to flake containing darwin modules
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";                                                                     # pin to nixpkgs 26.05
    flake-utils.url = "github:numtide/flake-utils";                                                                       # support eachSystem fan-out. see: https://github.com/numtide/flake-utils#eachsystem--system---system---attrs
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";                                                     # pin to nixpkgs 26.05 for MacOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";                                                     # support nix-darwin.lib.darwinSystem
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";                                                                 # inject pinned nixpkgs into nix darwin
  };
  outputs = {
    flake-utils,
    nixpkgs,
    nix-darwin,
    infrastructure,
    self,
    ...
  }: let
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  in flake-utils.lib.eachSystem supportedSystems (
    system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      packages = {
        #
        # darwin configuration is _normally_ defined as a top level output of a flake,
        # rather than as a package. However, nix darwin actually searches packages for
        # darwin configurations! This lets us make a separate darwin config for both
        # x86_64 AND for aarch64, using system fan-out
        #
        # it _also_ lets us completely avoid reading builtins env and impure evaluation
        # because both architectures are built here
        #
        # To see the configuration nix darwin will build, without installing it, run:
        #
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
          system = system;
          modules = with infrastructure.darwinModules; [
            (darwin { inherit pkgs self; })
            (do-not-manage-nix { inherit pkgs self; })
            (do-not-manage-shells { inherit pkgs self; })
            (packages { inherit pkgs self; })
            (security { inherit pkgs self; })
            {
              nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;
              # networking.hostName   # see https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/networking/default.nix#L45
            }
          ];
        };
      };
    }
  );
}
