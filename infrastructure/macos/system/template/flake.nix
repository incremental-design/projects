{
  description = ''
    nix-darwin configuration
  '';
  inputs = {
    infrastructure.url = "github:incremental-design/projects?dir=infrastructure"; # path to flake containing darwin modules
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # pin to nixpkgs 26.05
    flake-utils.url = "github:numtide/flake-utils"; # support eachSystem fan-out. see: https://github.com/numtide/flake-utils#eachsystem--system---system---attrs
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin"; # pin to nixpkgs 26.05 for MacOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"; # support nix-darwin.lib.darwinSystem
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin"; # inject pinned nixpkgs into nix darwin
  };
  outputs = {
    nix-darwin,
    infrastructure,
    self,
    ...
  }: let
    macos_system_arch = "aarch64-darwin";
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
      system = macos_system_arch;
      modules = with infrastructure.darwinModules; [
        (darwin {inherit pkgs self;})
        (do-not-manage-nix {inherit pkgs self;})
        (do-not-manage-shells {inherit pkgs self;})
        (packages {inherit pkgs self;})
        (security {inherit pkgs self;})
        {
          nixpkgs.hostPlatform = macos_system_arch;
          # networking.hostName   # see https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/networking/default.nix#L45
        }
      ];
    };
  };
}
