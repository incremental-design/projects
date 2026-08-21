{
  description = ''
    home-manager configuration
  '';
  inputs = {
    infrastructure.url = "github:incremental-design/projects?dir=infrastructure"; # path to flake containing home modules for macos
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # pin to nixpkgs 26.05
    home-manager.url = "github:nix-community/home-manager/release-26.05"; # load home-manager CLI. see: https://nix-community.github.io/home-manager/nix-flakes/standalone.html#sec-flakes-standalone
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {
    home-manager,
    infrastructure,
    nixpkgs,
    ...
  }: let
    username = "default";
    homeDirectory = "/Users/Default";
    system = "aarch64-darwin";
  in {
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system}; # home manager requires "legacyPackages" ... not updated nixkpgs { inherit system;}; -> nixpkgs flake
      #
      # extraSpecialArgs exposes inputs directly to outputs
      #
      # WITHOUT extra special args
      #            ______________
      #           /              |
      #          /   flake.nix   |
      #          |               |
      #          |               |
      #  inputs ---> transformed |      flake.nix takes inputs and
      #          |      into     |      turns them into outputs
      #          |       |       |
      #          |______ | ______|
      #                  |
      #                  |
      #                  V
      #               outputs
      #
      #
      # WITH extra special args
      #            ______________
      #           /              |
      #          /   flake.nix   |
      #          |               |
      #          |               |
      #  inputs ---------,       |      flake.nix takes inputs
      #          |       |       |      and injects them into
      #          |       |       |      modules, which transform
      #          |______ | ______|      them into outputs
      #                  |
      #                  |
      #                  V
      #               modules
      #                  |
      #           transformed into
      #                  |
      #                  V
      #               outputs
      #
      #
      # Extra special args passes all inputs through
      # to modules, which contain the logic needed
      # to transform them into outputs.
      #
      # Instead of keeping all the logic for transforming
      # inputs -> outputs in the flake.nix itself, the
      # logic is split up among modules. The flake.nix
      # can now become a dumb connector between the inputs
      # and the modules that create the outputs
      #
      # Note that you can transform inputs into outputs
      # in the flake.nix AND pass the raw inputs to modules
      # however it is simpler to make the flake a simple
      # manifest and to make the modules do the hard work
      # of transforming inputs -> outputs
      #
      extraSpecialArgs = {inherit inputs;};
      modules = with infrastructure.homeModules;
        [
          hm_macos
          zed_macos
        ]
        ++ [
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];
    };
  };
}
