# see parse-manifest-flake_nix.nix to find out how
# project-lint, project-lint-semver, project-build, and
# project-test are run against this flake
{
  description = "build and test for another";

  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";

    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
  };

  outputs = {
    flake-schemas,
    nixpkgs,
    self,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    # https://determinate.systems/blog/flake-schemas/#defining-your-own-schemas
    schemas =
      flake-schemas.schemas
      // {
        nixVersion = {
          version = 1;
          doc = "The nix version required to run this flake";
          type = "string";
        };
      };

    # nixVersion specifies the nix version needed to run this flake
    nixVersion = "2.33.1";

    packages = forEachSupportedSystem ({pkgs}: {
      default = pkgs.stdenv.mkDerivation {
        name = "another";
        src = "../../"; # Include entire repo as source
        version = "0.2";

        nativeBuildInputs = with pkgs; [
          coreutils
          # INCLUDE THE TOOLS YOU NEED TO BUILD YOUR PACKAGE HERE
        ];

        phases = [
          # "unpackPhase"
          # "patchPhase"
          # "configurePhase"
          "buildPhase"
          # "checkPhase"
          # "installPhase"
          # "fixupPhase"
          # "installCheckPhase"
        ];

        buildPhase = ''

          # make dirs included in package FHS
          # see https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
          #
          mkdir -p "$out"/{bin,lib,share,include}

          # copy executables to bin/ so they can be nix run
          # copy libraries to lib/
          # copy docs, data to share/
          # copy headers to include/
        '';
      };
    });

    checks = forEachSupportedSystem ({pkgs}: {
      exampleTest =
        pkgs.runCommand "exampleTest" {
          nativeBuildInputs = [self.packages.${pkgs.system}.default];
        } ''
          # name of bin to run default package
          echo "test passed" > "$out"
        '';
    });
  };
}
