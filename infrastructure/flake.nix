{
  description = ''
    - modules and installation scripts for all MacOS systems used at incremental.design

    infrastructure/
      |
      |- macos/
      |   |
      |   '- system/                  # configures systemwide packages, daemons, services
      |       |                       # and applications for all users
      |       |
      |       '- template/flake.nix   # template to copy into /var/root to configure nix-
      |                               # darwin
      |
      '- flake.nix                    # root flake that contains setup-host script, re-
                                      # exports modules for MacOS, NixOS
  '';
  inputs = {
    flake-utils.url = "github:numtide/flake-utils"; # support eachSystem fan-out. see: https://github.com/numtide/flake-utils#eachsystem--system---system---attrs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # pin to nixpkgs 26.05
    projects-flake.url = "../"; # input monorepo flake to add custom schema support
  };
  outputs = {
    flake-utils,
    nixpkgs,
    projects-flake,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in
    {
      schemas = projects-flake.schemas;
      nixVersion = "2.33.1";
      darwinModules = {
        darwin = import ./macos/system/darwin.nix;
        do-not-manage-nix = import ./macos/system/do-not-manage-nix.nix;
        do-not-manage-shells = import ./macos/system/do-not-manage-shells.nix;
        packages = import ./macos/system/packages.nix;
        security = import ./macos/system/security.nix;
      };
      templates = {
        macos = {
          path = ./macos/system/template;
          description = "darwin configuration template for macOS";
        };
      };
    }
    // flake-utils.lib.eachSystem supportedSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages = {
          install = pkgs.callPackage ./install.nix {};
        };
      }
    );
}
