{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";                         # support eachSystem fan-out. see: https://github.com/numtide/flake-utils#eachsystem--system---system---attrs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";                       # pin to nixpkgs 26.05
    projects-flake.url = "../";                                             # input monorepo flake to add custom schema support
  };
  outputs = {
    flake-utils,
    # nixpkgs,
    projects-flake,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    schemas = projects-flake.schemas;
    nixVersion = "2.33.1";
  }
  // flake-utils.lib.eachSystem supportedSystems (
    system:
    # let
    #   pkgs = import nixpkgs { inherit system; };
    # in
    {
      packages = {
      };
    }
  );
}
