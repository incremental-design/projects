{
  description = ''
    - modules and installation scripts for all MacOS systems used at incremental.design

    infrastructure/
      |
      |- macos/
      |   |
      |   |- system/                  # configures systemwide packages, daemons, services
      |   |   |                       # and applications for all users
      |   |   |
      |   |   '- template/flake.nix   # template to copy into /var/root to configure nix-
      |   |                           # darwin
      |   |
      |   '- home/                    # configures ~/ dotfiles, per-user applications,
      |       |                       # login shell, login agents
      |       |
      |       '- template/flake.nix   # template to copy into ~/ to configure home manager
      |
      '- flake.nix                    # root flake that contains setup-host script, re-
                                      # exports modules for MacOS, NixOS
  '';
  inputs = {
    flake-utils.url = "github:numtide/flake-utils"; # support eachSystem fan-out. see: https://github.com/numtide/flake-utils#eachsystem--system---system---attrs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # pin to nixpkgs 26.05
    projects-flake.url = "path:../"; # input monorepo flake to add custom schema support
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
        packages = import ./macos/system/packages.nix;
        security = import ./macos/system/security.nix;
        shells = import ./macos/system/shells.nix;
      };
      homeModules = {
        hm_macos = import ./macos/home/hm.nix;
        zed_macos = import ./macos/home/zed.nix;
        shells_macos = import ./macos/home/shells.nix;
      };
      templates = {
        macos = {
          path = ./macos/system/template;
          description = "darwin configuration template for macOS";
        };
        macos_home = {
          path = ./macos/home/template;
          description = "home manager configuration template for macOS";
        };
      };
    }
    // flake-utils.lib.eachSystem supportedSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages = {
          # pkgs.callPackage expands to
          # (import ./install.nix { pkgs.writeShellApplication, pkgs.coreutils, pkgs.gnused, pkgs.glow } // {})
          # where // {} is any overrides to pkg in pkgs or additional attrs not defined in pkgs
          install = pkgs.callPackage ./install.nix {};
        };
      }
    );
}
